#!/usr/bin/env perl
use warnings;
use strict;
use Data::Dumper qw(Dumper);
use IO::Socket;
use threads;

my $socket = IO::Socket::INET->new(
  LocalAddr => '127.0.0.1',
  LocalPort => '7770',
  Type => SOCK_STREAM,
  Proto => 'tcp',
  Listen => 10,
  Timeout => 120,
  RescueAddr => SO_REUSEADDR,
) or die $@;

$SIG{INT} = $SIG{TERM} = sub{
  $socket->close() or warn "Close socket failed!";
};

while(my $client = $socket->accept()){
  threads->create("handle", $client)->detach();
}

sub handle{
  my ($client) = @_;
  my $uuid = `uuidgen`;
  $uuid =~ s/\s+$//g;
  $client->send($uuid);
}
