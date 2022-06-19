class hazelcast(
  $version = '4.2.5',
  $user = 'dev',
  $password = 'dev'
  )



  file { "/usr/share/tomcat8/mancenter":
    ensure => directory,
    group => "root",
    owner => "root",
    mode => "0750",
    require => Package['tomcat8']
  }

  file { "/opt/hazelcast":
    ensure => directory,
    group => "root",
    owner => "root",
    mode => "0644",
  }

  exec { "download-hazelcast":
    command => "/usr/bin/wget https://github.com/hazelcast/hazelcast/releases/download/v${version}/hazelcast-${version}.zip -P /opt",
    creates => "/opt/hazelcast-${version}.zip"
  }

  exec { "unpack-hazelcast":
    command => "/usr/bin/unzip /opt/hazelcast-${version}.zip -d /opt",
    require => [ Exec["download-hazelcast"], Package['unzip']],
    creates => "/opt/hazelcast-${version}",
  }

  file { "/etc/init/hazelcast.conf":
    ensure => present,
    group => "root",
    owner => "root",
    mode => "0644",
    content => template('hazelcast/hazelcast.conf.erb'),
    require => Package["java"],
    notify => Service["hazelcast"],
  }

  service { 'hazelcast':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require => File["/etc/init/hazelcast.conf"],
  }

  file { "/var/lib/tomcat8/webapps/mancenter.war":
    sourceselect => 'first',
    ensure => present,
    group => "root",
    owner => "root",
    mode => "0644",
    source => [
      "/opt/hazelcast-${version}/mancenter.war",
      "/opt/hazelcast-${version}/mancenter-${version}.war",
      "/opt/hazelcast-${version}/mancenter-${majorVersion}.war"
    ],
    require => File["/opt/hazelcast-${version}/bin/hazelcast.xml"],
    notify => Service['tomcat8']
  }

  file { "/opt/hazelcast-${version}/bin/hazelcast.xml":
    ensure => present,
    group => "root",
    owner => "root",
    mode => "0644",
    content => template("hazelcast/hazelcast-${version}.xml.erb"),
    require => Exec["unpack-hazelcast"],
    notify => Service['hazelcast']
  }
}