# Foswiki - The Free and Open Source Wiki, http://foswiki.org/
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

use strict;

package Foswiki::Contrib::XmlRpcContrib;

our $VERSION = '$Rev$';
our $RELEASE = '1.00';
our $SERVER;
our %handler;
our $SHORTDESCRIPTION = '';

################################################################################
# register an implementation for a handler
sub registerRPCHandler {
  my ($methodName, $methodImpl) = @_;

  # SMELL: this may override a previous registration; must we take care?
  $handler{$methodName} = $methodImpl;
}

################################################################################
# process an xml call
sub dispatch {
  my ($session, $data) = @_;

  $Foswiki::Plugins::SESSION = $session;

  initServer();
  unless ($data) {
    my $query = $session->{cgiQuery};
    $data = $query->param('POSTDATA') || '';
  }

  return $SERVER->dispatch($session, $data);
}

################################################################################
# create a singleton server object
sub initServer {

  return if $SERVER;
  require Foswiki::Contrib::XmlRpcContrib::Server;
  $SERVER = Foswiki::Contrib::XmlRpcContrib::Server->new(%handler);
  return $SERVER;
}


1;
