#!/usr/bin/env perl
use warnings;
use strict;
use Data::Dumper qw(Dumper);
use IO::Socket;

my $socket = IO::Socket::INET->new(
  PeerAddr => '127.0.0.1',
  PeerPort => '7770',
  Type => SOCK_STREAM,
  Proto => 'tcp',
) or die $@;
$socket->send("Hello Server\n");
$socket->recv(my $uuid, 1024);
print Dumper $uuid;
close($socket);
