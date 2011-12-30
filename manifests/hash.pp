define postfix::hash (
  $ensure=present
) {
  file { $name:
    ensure => $ensure,
    mode   => '0600',
    require => Package['postfix'],
  }

  file { "${name}.db":
    ensure  => $ensure,
    mode    => '0600',
    notify  => Exec["generate ${name}.db"],
    require => File[$name],
  }

  exec {"generate ${name}.db":
    command     => "postmap ${name}",
    subscribe   => File[$name],
    refreshonly => true,
    require     => Package['postfix'],
  }
}
