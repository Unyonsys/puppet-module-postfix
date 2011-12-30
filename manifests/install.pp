class postfix::install (
  $postfix_smtpd_tls,
  $postfix_ldap_support,
  $use_greylisting
  ) {

  if $postfix_ldap_support and $postfix_smtpd_tls {
    $postfix_groups      = [ 'sasl', 'mail', 'ssl-cert' ]
  }
  elsif $postfix_ldap_support {
    $postfix_groups = [ 'sasl', 'mail' ]
  }
  elsif $postfix_smtpd_tls {
    $postfix_groups = [ 'ssl-cert' ]
  }
  else {
    $postfix_groups = undef
  }

  user { 'postfix':
    groups  => $postfix_groups,
    require => Package['postfix'],
  }

  package { 'postfix':
    ensure  => present,
  }

  if $use_greylisting {
    package { 'postgrey':
      ensure => present
    }
  }

  if $postfix_ldap_support {
    User ['postfix'] -> Package[ 'sasl2-bin']

    package { 'postfix-ldap':
      ensure => present
    }
  }

  file { '/usr/local/bin/postfix-flush-byemail.pl':
    ensure => file,
    source => 'puppet:///modules/postfix/postfix-flush-byemail.pl',
    mode   => '0755',
  }
}

