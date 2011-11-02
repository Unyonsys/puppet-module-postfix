define postfix::virtual ($ensure="present", $destination) {
    line {"${name}":
        ensure => $ensure,
        file   => "/etc/postfix/virtual",
        line   => "${name} ${destination}",
        notify => Exec["generate /etc/postfix/virtual.db"],
        require => Package['postfix'],
    }
}