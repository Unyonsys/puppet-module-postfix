class postfix (
  $managed_mail_domains             = false,
  $root_mail_alias                  = false,
  $postfix_exported_mynetworks      = false,
  $postfix_mydestination_complement = [],
  $postfix_relayhost                = false,
  $postfix_sasl_type                = 'cyrus',
  $postfix_message_size_limit       = 61440000,
  $postfix_smtpd_tls                = false,
  $tls_cert                         = false,
  $tls_ca                           = false,
  $tls_chain                        = false,
  $tls_key                          = false,
  $postfix_ldap_support             = false,
  $authentication_ldap_servers      = false,
  $ldap_bind_dn                     = false,
  $ldap_bind_pw                     = false,
  $accounts_query_filter            = '(&(objectClass=gosaMailAccount)(mail=%s))',
  $aliases_query_filter             = '(&(objectClass=gosaMailAccount)(|(mail=%s)(gosaMailAlternateAddress=%s)))',
  $result_attribute                 = 'mail',
  $amavis                           = false
  ) {
  package { 'postfix': ensure => present }

  
  if $postfix_ldap_support and $postfix_smtpd_tls {
    $postfix_groups = [ 'sasl', 'mail', 'ssl-cert' ]
    $postfix_pkg_require = 'sasl2-bin'
  }
  elsif $postfix_ldap_support {
    $postfix_groups = [ 'sasl', 'mail' ]
  }
  elsif $postfix_smtpd_tls {
    $postfix_groups = [ 'ssl-cert' ]
  }
  else {
    $postfix_groups = false
  }

  if $postfix_groups {
    user { 'postfix':
      groups  => $postfix_groups,
      require => Package[postfix],
    }
  }

  if $postfix_smtpd_tls {
    if $tls_ca and $tls_chain {
      fail('Please provide $tls_ca or $tls_chain, NOT both.')
    }
    include ssl::variables
    Ssl::Cert[$tls_cert]      -> Class['postfix']

    if $tls_ca {
      Ssl::Cert[$tls_ca]      -> Class['postfix']
    }
    elsif $tls_chain {
      Ssl::Chain[$tls_chain]  -> Class['postfix']
    }
    else {
      fail('You must provide $tls_ca or $tls_chain.')
    }
  }
  
  if $amavis {
    Class['amavis'] -> Class['postfix']
  }

  concat { '/etc/postfix/main.cf':
    owner   => root,
    group   => root,
    mode    => 0644,
    warn    => "# This file is managed by puppet, do not edit manually\n\n",
    require => Package['postfix'],
    notify  => Service['postfix'],
  }

  concat::fragment { 'main.cf.base':
    target  => '/etc/postfix/main.cf',
    order   => 05,
    content => template('postfix/main.cf.base.erb')
  }

  file { '/etc/postfix/master.cf':
    ensure    => file,
    mode      => 0644,
    content   => template('postfix/master.cf.erb'),
    require   => Package['postfix'],
    notify    => Service['postfix'],
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
  
  file { '/etc/postfix/sasl/smtpd.conf':
    ensure   => file,
    mode     => 0644,
    content  => "pwcheck_method: saslauthd\nmech_list: plain\n",
    require  => Package['postfix'],
    notify   => Service['postfix'],
  }
  
  concat { '/etc/postfix/exported_mynetworks':
    mode    => 0644,
    force   => true,
    warn    => true,
    require => Package['postfix'],
    notify  => Service['postfix'],
  }

  Postfix::Exportedmynetworks <<| |>>
  
  service { 'postfix':
    ensure      => running,
    enable      => true,
    hasstatus   => true,
    hasrestart  => true,
    require     => Package['postfix'],
  }

  exec { 'newaliases':
    command     => '/usr/bin/newaliases',
    refreshonly => true,
    require     => Package['postfix'],
  }

  postfix::alias { 'root':          destination => $root_mail_alias }
  postfix::alias { 'postmaster':    destination => 'root' }
  postfix::alias { 'mailer-daemon': destination => 'root' }
  postfix::hash  { '/etc/postfix/virtual': ensure => present }
  
  if $postfix_ldap_support {
    if ! $authentication_ldap_servers or ! $ldap_bind_dn or ! $ldap_bind_pw{
      fail('You must provide valid values for LDAP connection.')
    }
    
    User ['postfix'] -> Package[ 'sasl2-bin']
  
    package { 'postfix-ldap':
      ensure => present
    }
  
    file { '/etc/postfix/ldap':
      ensure  => directory,
      mode    => 0755,
      require => Package['postfix'],
      notify  => Service['postfix'],
    }
  
    file { '/etc/postfix/ldap/accounts.cf':
      ensure   => file,
      mode     => 0644,
      content  => template('postfix/ldap/accounts.cf.erb'),
      require  => Package['postfix'],
      notify   => Service['postfix'],
    }
  
    file { '/etc/postfix/ldap/aliases.cf':
      ensure   => file,
      mode     => 0644,
      content  => template('postfix/ldap/aliases.cf.erb'),
      require  => Package['postfix'],
      notify   => Service['postfix'],
    }
  }
}
