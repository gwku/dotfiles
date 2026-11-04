{ ... }: {
  # Client identity, credentials, consent, and OS privacy grants stay local.
  # Do not start a remote-control service or change access permissions on switch.
  homebrew.casks = [ "rustdesk" ];
}
