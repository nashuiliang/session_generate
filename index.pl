#!/usr/bin/env perl
package MyServer;
use warnings qw(all);
use strict qw(refs vars subs);
use Data::Dumper qw(Dumper);
use IO::Socket;
use autodie;
use Redis;
use HTTP::Server::Simple::CGI;
use base qw(HTTP::Server::Simple::CGI);
use JSON qw(encode_json);
use Storable qw(thaw);

sub session_id{
  my $socket = IO::Socket::INET->new(
    PeerHost => 'localhost',
    PeerPort => '7770',
    Type => SOCK_STREAM,
    Proto => 'tcp',
  );
  $socket->recv(my $res, 1024);
  close($socket);

  $res =~ s/\s+$//g;
  my $info = thaw($res);
  return $info->{uuid};
}

sub init_session{
  my ($ip, $user_agent, $sid) = @_;
  my $r = Redis->new(host => 'localhost', port => 6379);
  if(!$sid || !$r->hexists("session:$sid", 'id')){
    $sid = session_id();
    $r->hmset("session:$sid", id => "$sid", ip_addr => $ip, user_agent => $user_agent, last_activity => time(), user_data => '');
  }
  ($r, $sid);
}

sub set_session{
  my ($r, $sid, $name) = @_;
  $r->hmset("session:$sid", user_data => "name=$name", last_activity => time());
  $r->expire("session:$sid", 10);
}

sub get_session{
  my ($r, $sid) = @_;
  $r->hgetall("session:$sid");
}

sub handle_request{
  my ($self, $cgi) = @_;
  my ($redis, $session_id) = init_session($ENV{REMOTE_HOST}, $ENV{HTTP_USER_AGENT}, $cgi->cookie('my_session_id'));
  my $user_name = $cgi->param('name');
  if($user_name){
    set_session($redis, $session_id, $user_name);
  }
  my %user_info = get_session($redis, $session_id);
  my $cookie = $cgi->cookie(-name => 'my_session_id', -value => $user_info{id}, -expires => '+30s');
  if(!$user_name){
    print "HTTP/1.1 200 OK\r\n";
    print $cgi->header(-cookie=>$cookie, -type => 'text/html'),
          $cgi->start_html("Hello World"),
          $cgi->h1("Hi"),
          $cgi->p(encode_json(\%user_info)),
          $cgi->p('<a href="/?name=xiaoxiao">set name=xiaoxiao</a>'),
          $cgi->end_html();
  }else{
    print "HTTP/1.1 200 OK\r\n";
    print $cgi->header(-cookie=>$cookie, -type => 'text/html'),
          $cgi->start_html("Hello World"),
          $cgi->h1("Hi"),
          $cgi->p(encode_json(\%user_info)),
          $cgi->p("$user_info{user_data}</a>"),
          $cgi->end_html();
  }
}

MyServer->new(8080)->run();
