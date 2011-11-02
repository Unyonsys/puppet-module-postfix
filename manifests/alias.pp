define postfix::alias (
  $destination
  ) {
  mailalias { $name:
    recipient => $destination,
    notify    => Exec['newaliases'],
  }
}