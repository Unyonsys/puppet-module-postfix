class postfix::service (
  $use_greylisting
  ) {

  service { 'postfix':
    ensure      => running,
    enable      => true,
    hasstatus   => true,
    hasrestart  => true,
  }

  if $use_greylisting {
    service { 'postgrey':
      ensure      => running,
      enable      => true,
      hasstatus   => true,
      hasrestart  => true,
    }
  }
}

