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
  $use_greylisting                  = false,
  $amavis                           = false
  ) {

  Class['postfix::install'] -> Class['postfix::config'] ~> Class['postfix::service']
  if $amavis {
    Class['amavis'] -> Class['postfix::install']
  }

  class { 'postfix::install':
    postfix_smtpd_tls    => $postfix_smtpd_tls,
    postfix_ldap_support => $postfix_ldap_support,
    use_greylisting      => $use_greylisting
  }
  
  class { 'postfix::config':
    managed_mail_domains             => $managed_mail_domains,
    root_mail_alias                  => $root_mail_alias,
    postfix_mydestination_complement => $postfix_mydestination_complement,
    postfix_relayhost                => $postfix_relayhost,
    postfix_sasl_type                => $postfix_sasl_type,
    postfix_message_size_limit       => $postfix_message_size_limit,
    postfix_smtpd_tls                => $postfix_smtpd_tls,
    tls_chain                        => $tls_chain,
    tls_key                          => $tls_key,
    postfix_ldap_support             => $postfix_ldap_support,
    authentication_ldap_servers      => $authentication_ldap_servers,
    ldap_bind_dn                     => $ldap_bind_dn,
    ldap_bind_pw                     => $ldap_bind_pw,
    accounts_query_filter            => $accounts_query_filter,
    aliases_query_filter             => $aliases_query_filter,
    result_attribute                 => $result_attribute,
    use_greylisting                  => $use_greylisting,
    amavis                           => $amavis
  }
  class { 'postfix::service':
    use_greylisting => $use_greylisting
  }

  postfix::alias { 'root':          destination => $root_mail_alias }
  postfix::alias { 'postmaster':    destination => 'root' }
  postfix::alias { 'mailer-daemon': destination => 'root' }
}

