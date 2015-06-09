package WebService::SaltAPI;
$VERSION = '0.1.0';

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Headers;
use JSON;

my $headers = HTTP::Headers->new();
$headers->header('Accept' => 'application/json');

my $ua = LWP::UserAgent->new();
$ua->agent('Salt API Perl Connector');
$ua->default_headers($headers);


sub new {
    my ( $class, $self ) = @_;
    die 'Expecting hash ref to new' unless ref $self eq 'HASH';
    bless $self, $class;
    $self->{'eauth'} ||= 'pam';
    $self->{'token'} = $self->new_token();
    $headers->header('X-Auth-Token' => $self->{'token'});
    return $self;
}

sub new_token {
    my ( $self ) = @_;
    die 'master does not exist in self'   unless exists $self->{'master'};
    die 'username does not exist in self' unless exists $self->{'username'};
    die 'password does not exist in self' unless exists $self->{'password'};
    die 'eauth does not exist in self'    unless exists $self->{'eauth'};
    my $token_url = "$self->{'master'}/login";
    my $response = $ua->post(
        $token_url, {
            'username' => $self->{'username'},
            'password' => $self->{'password'},
            'eauth'    => $self->{'eauth'},
        }
    );
    my $token_info;
    eval { $token_info = decode_json $response->content() };
    die "$@" if $@;
    return $token_info->{'return'}[0]->{'token'};
}

sub cmd {
    my ( $self, $job_data ) = @_;
    die 'master does not exist in self' unless exists $self->{'master'};
    $job_data->{'client'} ||= 'local';

    my $command_url = "$self->{'master'}/minions";
    my $response = $ua->post($command_url, $job_data);

    return decode_json $response->content();
}

sub job {
    my ( $self, $jid ) = @_;

    my $command_url = "$self->{'master'}/jobs/$jid";
    my $response = $ua->get($command_url);

    return decode_json $response->content();
}

sub run {
    my ( $self, $job_data ) = @_;
    $job_data->{'client'}   ||= 'local';
    $job_data->{'username'} ||= $self->{'username'};
    $job_data->{'password'} ||= $self->{'password'};
    $job_data->{'eauth'}    ||= $self->{'eauth'};

    my $command_url = "$self->{'master'}/run";
    my $response = $ua->post($command_url, $job_data);

    return decode_json $response->content();
}

1;

__END__

=head1 NAME

WebService::SaltAPI

=head1 SYNOPSIS

 use WebService::SaltAPI;
 use JSON;
 use Data::Dumper;

 my $salt = WebService::SaltAPI->new({
     'master'   => 'https://saltapi.example.com:8080',
     'username' => 'mallory',
     'password' => '123pass',
 });
 
 my $job = $salt->cmd({
     'tgt' => 'sterling',
     'fun' => 'test.ping',
 });
 print Dumper $salt->job($job->{'return'}[0]->{'jid'});

 print Dumper $salt->run({
     'tgt' => 'sterling',
     'fun' => 'status.diskusage',
     'arg' => '/',
 });

 print Dumper $salt->run({
     'tgt' => 'sterling',
     'fun' => 'status.diskusage',
     'arg' => ['/', '/tmp'],
 });

 print Dumper $salt->run({
     'tgt' => 'sterling',
     'fun' => 'test.echo',
     'arg' => encode_json {'text' => 'Hello world!'},
 });

=head1 DESCRIPTION

C<WebService::SaltAPI> is a module that provides Perl bindings to the REST API
service provided by Salt API.

=head1 METHODS

=over 4

=item $salt = WebService::SaltAPI->new( $credentials )

=back

 my $salt = WebService::SaltAPI->new({
     'master'   => 'https://saltapi.example.com:8080',
     'username' => 'mallory',
     'password' => '123pass',
 });

=over 4

=item $job = $salt->cmd( $arguments )

=back

 my $job = $salt->cmd({
     'tgt' => 'sterling',
     'fun' => 'test.ping',
 });
 print Dumper $salt->job($job->{'return'}[0]->{'jid'});

=over 4

=item $job = $salt->run( $arguments )

=back

 print Dumper $salt->run({
     'tgt' => 'sterling',
     'fun' => 'status.diskusage',
     'arg' => '/',
 });

 print Dumper $salt->run({
     'tgt' => 'sterling',
     'fun' => 'status.diskusage',
     'arg' => ['/', '/tmp'],
 });

=over 4

=item $job = $salt->run( $arguments )

=back

 print Dumper $salt->run({
     'tgt' => 'sterling',
     'fun' => 'test.echo',
     'arg' => encode_json {'text' => 'Hello world!'},
 });

=head1 COPYRIGHT

Copyright 2015 Joseph Hall

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
