package Net::ConoHa::API;

use strict;
use warnings;
use utf8;

use base qw/Class::Accessor/;
use HTTP::Tiny;
use JSON;

use constant TOKEN_URL   => "https://identity.tyo1.conoha.io/v2.0/tokens";
use constant BILLING_URL => "https://account.tyo1.conoha.io/v1/%s/billing-invoices";
use constant LIST_URL    => "https://compute.tyo1.conoha.io/v2/%s/servers";


sub new
{
  my ($class, $config)= @_;
  my $self= {token  => undef,
             config => $config,
             http   => undef};

  my $http   = HTTP::Tiny->new(default_headers => {Accept => "application/json"});
  my $content= to_json({auth => {passwordCredentials => $config}});
  my $token;
  if (my $ret= $http->post(TOKEN_URL, {content => $content}))
  {
    $token= from_json($ret->{content})->{access}->{token}->{id};
  }

  bless $self => $class;
  $class->mk_accessors(keys(%$self));
  $self->token($token);
  $self->http(HTTP::Tiny->new(default_headers => {"Accept"       => "application/json",
                                                  "X-Auth-Token" => $token}));

  return $self if $self->{token};
}


sub billing
{
  my ($self)= @_;
  my $url= sprintf(BILLING_URL, $self->config->{tenantId});

  my $ret= $self->http_get($url)->{billing_invoices}->[0]->{bill_plus_tax};
  return 0 unless $ret;
  return $ret;
}


sub vm_list
{
  my ($self)= @_;
  my $url= sprintf(LIST_URL, $self->config->{tenantId});

  my $ret= $self->http_get($url);
  return 0 unless $ret;

  my @list;
  foreach (@{$ret->{servers}})
  {
    push(@list, $_->{name});
  }
  return \@list;
}


sub http_get
{
  my ($self, $url)= @_;

  if (my $ret= from_json($self->http->get($url)->{content}))
  {
    return $ret;
  }
  else
  {
    return 0;
  }
}


return 1;
