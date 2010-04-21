# XML-RPC server 4 Foswiki
#
# Copyright (C) 2006-2010 Michael Daum http://michaeldaumconsulting.com
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version. For
# more details read LICENSE in the root of this distribution.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# As per the GPL, removal of this notice is prohibited.

package Foswiki::Contrib::XmlRpcContrib::Server;

use RPC::XML ();
use RPC::XML::Parser ();

use constant DEBUG => 0; # toggle me

################################################################################
# static
sub writeDebug {
  print STDERR '- XmlRpcContrib::Server - '.$_[0]."\n" if DEBUG;
}

################################################################################
# constructor
sub new {
  my ($class, %handler) = @_;

  writeDebug("called constructor");

  my $this = {
    parser=> RPC::XML::Parser->new(),
    session=>'',
  };

  foreach my $methodName (keys %handler) {
    my $methodImpl = $handler{$methodName};
    writeDebug("new handler $methodName=$methodImpl");
    $this->{handler}{$methodName} = $methodImpl;
  }

  return bless($this, $class);
}

################################################################################
sub getError  {
  my ($this, $status, $error, $data) = @_;

  return $this->getResponse($status, RPC::XML::fault->new($error, $data));
}

################################################################################
sub getResponse {
  my ($this, $status, $data) = @_;

  my $response = RPC::XML::response->new($data);

  return 
    "Status: $status\n".
    "Content-Type: text/xml\n\n".
    $response->as_string;
}

################################################################################
sub dispatch {
  my ($this, $session, $data) = @_;

  writeDebug("called dispatch");
  writeDebug("data=$data");

  # check ENV
  if ($ENV{'REQUEST_METHOD'} ne 'POST') {
    return $this->getError('405 Method Not Allowed', -32300, 'Only XML-RPC POST requests recognised.');
  }

  if ($ENV{'CONTENT_TYPE'} ne 'text/xml') {
    return $this->getError('415 Unsupported Media Type', -32300, 'Only XML-RPC POST requests recognised.');
  }

  # parse
  my $request = $this->{parser}->parse($data);
  return $this->getError('400 Bad Request', -32700, $request) unless ref($request);

  # check impl
  my $name = $request->name;
  unless ($this->{handler}{$name}) {
    return $this->getError('501 Not Implemented', -32601, "Method $name not supported");
  }

  # call 
  $session->enterContext($name);
  my ($status, $error, $result) = &{$this->{handler}{$name}}($session, $request->args);
  $session->leaveContext($name);

  writeDebug("status=$status");
  writeDebug("error=$error");
  writeDebug("result=$result");

  # print response
  my $response;
  if ($error == 0) {
    $result = RPC::XML::string->new($result) if not ref $result;
    $response = $this->getResponse($status, $result); # default 
  } else {
    $response = $this->getError($status, $error, $result); # error
  }
  writeDebug("response=$response");
  return $response;
}

1;
