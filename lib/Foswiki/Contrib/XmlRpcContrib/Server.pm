# XML-RPC server for Foswiki
#
# Copyright (C) 2006-2025 Michael Daum http://michaeldaumconsulting.com
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

=begin TML

---+ package Foswiki::Contrib::XmlRpcContrib::Server

=cut

use strict;
use warnings;

use RPC::XML ();
use RPC::XML::Parser ();
use Error qw( :try );

use constant TRACE => 0; # toggle me



=begin TML

---++ ClassMethod new() 

constructor

predefined error codes:
   * -32700: parse error. not well formed
   * -32701: parse error. unsupported encoding
   * -32702: parse error. invalid character for encoding
   * -32600: server error. invalid xml-rpc. not conforming to spec.
   * -32601: server error. requested method not found
   * -32602: server error. invalid method parameters
   * -32603: server error. internal xml-rpc error
   * -32500: application error
   * -32400: system error
   * -32300: transport error

=cut

sub new {
  my $class = shift;

  _writeDebug("called constructor");

  my $this = {
    parser=> RPC::XML::Parser->new(),
    session=>'',
  };

  return bless($this, $class);
}

=begin TML

---++ ObjectMethod registerMethod($methodName, $fnref, %options) 

register a method for the given callback

=cut

sub registerMethod {
  my ($this, $methodName, $fnref, %options) = @_;

  _writeDebug("registerMethod($methodName, $fnref)");

  $this->{handler}{$methodName} = {
    function => $fnref,
    %options
  };
}

=begin TML

---++ ObjectMethod dispatch($session, $data) 

dispatch the xmlrpc call as configured to the Foswiki switchboard

=cut

sub dispatch {
  my ($this, $session, $data) = @_;

  _writeDebug("called dispatch");
  $this->{session} = $session;

  unless (defined $data) {
    my $query = $session->{cgiQuery};
    $data = $query->param('POSTDATA') || '';
  }

  #_writeDebug("data=$data");

  # check ENV
  if ($ENV{'REQUEST_METHOD'} ne 'POST') {
    $this->printError('405 Method Not Allowed', -32300, 'Only XML-RPC POST requests recognised.');
    return;
  }

  if ($ENV{'CONTENT_TYPE'} ne 'text/xml') {
    $this->printError('415 Unsupported Media Type', -32300, 'Only XML-RPC POST requests recognised.');
    return;
  }

  # parse
  my $request = $this->{parser}->parse($data);
  unless (ref($request)) {
    $this->printError('400 Bad Request', -32700, $request) unless ref($request);
    return;
  }

  # get handler
  my $name = $request->name;
  my $handler = $this->{handler}{$name};

  # check impl
  unless ($handler) {
    $this->printError('501 Not Implemented', -32601, "Method $name not supported");
    return;
  }

  # call 
  my $result;
  my $status;
  my $error;
  $session->enterContext($name);
  try {
    no strict 'refs';
    my $function = $handler->{function};
    ($status, $error, $result) = &$function($session, $request->args);
    use strict 'refs';
  } catch Error::Simple with {
    $status = '500 Server Error';
    $error  = -32500;
    $result = "Internal server error".shift;
  };
  $session->leaveContext($name);

  _writeDebug("status=$status");
  _writeDebug("error=$error");
  _writeDebug("result=$result");

  # print response
  if ($error == 0) {
    $result = RPC::XML::string->new($result) if not ref $result;
    $this->print($status, $this->getResponse($result)); # default 
  } else {
    $this->printError($status, $error, $result); # error
  }

  return;
}

=begin TML

---++ ObjectMethod getError ($error, $data) -> $error

creates an error for the current response

=cut

sub getError  {
  my ($this, $error, $data) = @_;

  return $this->getResponse(RPC::XML::fault->new($error, $data));
}

=begin TML

---++ ObjectMethod getResponse($data)  -> $response

returns an RPC::XML::response for the given data

=cut

sub getResponse {
  my ($this, $data) = @_;

  return RPC::XML::response->new($data);
}

=begin TML

---++ ObjectMethod printError($status, $error, $data) 

=cut

sub printError {
  my ($this, $status, $error, $data) = @_;

  $this->print($status, $this->getError(-32300, 'Only XML-RPC POST requests recognised.'));
}

=begin TML

---++ ObjectMethod print($status, $response) 

prints the result to the session response object

=cut

sub print {
  my ($this, $status, $response) = @_;

  $this->{session}{response}->header(
    -status  => $status,
    -type    => 'text/plain',
  );

  $this->{session}->{response}->print($response->as_string);
}

# statuc
sub _writeDebug {
  print STDERR '- XmlRpcContrib::Server - '.$_[0]."\n" if TRACE;
}

1;
