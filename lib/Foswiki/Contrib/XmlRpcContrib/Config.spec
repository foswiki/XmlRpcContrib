# ---+ Extensions
# ---++ XmlRpcContrib
# **PERL H** 
# This setting is required to enable executing xmlrpc from the bin directory
$Foswiki::cfg{SwitchBoard}{xmlrpc} = ['Foswiki::Contrib::XmlRpcContrib', 'dispatch', {xmlrpc => 1}];
