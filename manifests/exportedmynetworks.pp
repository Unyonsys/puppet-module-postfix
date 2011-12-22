define postfix::exportedmynetworks(
  $address
  ) {
  concat::fragment{ "postfixexportedmynetworks_${address}" :
    target  => '/etc/postfix/exported_mynetworks',
    order   => 50,
    content => "${address}\n"
  }
}
