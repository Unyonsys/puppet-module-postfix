class postfix::config (
  $managed_mail_domains,
  $root_mail_alias,
  $postfix_mydestination_complement,
  $postfix_relayhost,
  $postfix_sasl_type,
  $postfix_message_size_limit,
  $postfix_smtpd_tls,
  $tls_cert,
  $tls_ca,
  $tls_chain,
  $tls_key,
  $postfix_ldap_support,
  $authentication_ldap_servers,
  $ldap_bind_dn,
  $ldap_bind_pw,
  $accounts_query_filter,
  $aliases_query_filter,
  $result_attribute,
  $use_greylisting,
  $amavis
) {
  if $postfix_smtpd_tls {
    #This ensures variables are properly defined in main.cf for
    #the SSL part
    include ssl::variables
  }

  concat { '/etc/postfix/main.cf':
    owner   => root,
    group   => root,
    mode    => '0644',
    warn    => true,
  }

  concat::fragment { 'main.cf.base':
    target  => '/etc/postfix/main.cf',
    order   => 05,
    content => template('postfix/main.cf.base.erb')
  }

  file { '/etc/postfix/master.cf':
    ensure    => file,
    mode      => '0644',
    content   => template('postfix/master.cf.erb'),
  }

  file { '/etc/mailname':
      ensure  => present,
      content => "${domain}\n",
  }

  file { '/etc/aliases':
      ensure  => present,
      content => "# file managed by puppet\n",
      replace => false,
      notify  => Exec['newaliases']
  }

  concat { '/etc/postfix/exported_mynetworks':
    mode    => '0644',
    force   => true,
    warn    => true,
  }

  concat { '/etc/postfix/virtual':
    mode   => '0644',
    force  => true,
    warn   => true,
    notify => Exec['newvirtualaliases']
  }

  exec { 'newaliases':
    command     => '/usr/bin/newaliases',
    refreshonly => true,
    require     => Concat['/etc/postfix/main.cf'],
  }

  exec { 'newvirtualaliases':
    command     => '/usr/sbin/postmap /etc/postfix/virtual',
    refreshonly => true,
    require     => Concat['/etc/postfix/main.cf'],
  }

  if $postfix_smtpd_tls {
    include ssl::variables
    Ssl::Chain[$tls_chain]  -> Class['postfix']

    file { '/etc/postfix/sasl/smtpd.conf':
      ensure   => file,
      mode     => '0644',
      content  => "pwcheck_method: saslauthd\nmech_list: plain\n",
    }
  }

  if $postfix_ldap_support {
    if ! $authentication_ldap_servers or ! $ldap_bind_dn or ! $ldap_bind_pw{
      fail('You must provide valid values for LDAP connection.')
    }

    file { '/etc/postfix/ldap':
      ensure  => directory,
      mode    => '0755',
    }

    file { '/etc/postfix/ldap/accounts.cf':
      ensure   => file,
      mode     => '0644',
      content  => template('postfix/ldap/accounts.cf.erb'),
    }

    file { '/etc/postfix/ldap/aliases.cf':
      ensure   => file,
      mode     => '0644',
      content  => template('postfix/ldap/aliases.cf.erb'),
    }
  }
}

