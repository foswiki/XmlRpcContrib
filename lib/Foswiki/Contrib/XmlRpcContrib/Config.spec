# ---+ Extensions
# ---++ XmlRpcContrib
# **PERL EXPERT H** 
# This setting is required to enable executing xmlrpc from the bin directory
$Foswiki::cfg{SwitchBoard}{xmlrpc} = {
  package => 'Foswiki::Contrib::XmlRpcContrib', 
  function => 'dispatch', 
  context => {xmlrpc => 1},
};

1;
