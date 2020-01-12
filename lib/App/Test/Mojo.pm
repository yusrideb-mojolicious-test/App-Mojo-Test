package App::Test::Mojo;
use Mojo::Base -base;

# "Amy: He knows when you are sleeping.
#  Professor: He knows when you're on the can.
#  Leela: He'll hunt you down and blast your ass from here to Pakistan.
#  Zoidberg: Oh.
#  Hermes: You'd better not breathe, you'd better not move.
#  Bender: You're better off dead, I'm telling you, dude.
#  Fry: Santa Claus is gunning you down!"
use Mojo::IOLoop;
use Mojo::JSON 'j';
use Mojo::JSON::Pointer;
use Mojo::Server;
use Mojo::UserAgent;
use Mojo::Util qw(decode encode);
use Test::More ();

has [qw(message success tx)];
has ua =>
  sub { Mojo::UserAgent->new(insecure => 1)->ioloop(Mojo::IOLoop->singleton) };

# Silent or loud tests
$ENV{MOJO_LOG_LEVEL} ||= $ENV{HARNESS_IS_VERBOSE} ? 'debug' : 'fatal';

sub app {
  my ($self, $app) = @_;
  return $self->ua->server->app unless $app;
  $self->ua->server->app($app);
  return $self;
}

sub attr_is {
  my ($self, $selector, $attribute, $value, $desc) = @_;
  return $self->_test('is', $self->_attr($selector, $attribute),
    $value, _desc($desc, qq{exact match for attribute "$attribute" at selector "$selector"}));
}

sub attr_isnt {
  my ($self, $selector, $attribute, $value, $desc) = @_;
  return $self->_test('isnt', $self->_attr($selector, $attribute),
    $value, _desc($desc, qq{no match for attribute "$attribute" at selector "$selector"}));
}

sub attr_like {
  my ($self, $selector, $attribute, $regex, $desc) = @_;
  return $self->_test('like', $self->_attr($selector, $attribute),
    $regex, _desc($desc, qq{similar match for attribute "$attribute" at selector "$selector"}));
}

sub attr_unlike {
  my ($self, $selector, $attribute, $regex, $desc) = @_;
  return $self->_test('unlike', $self->_attr($selector, $attribute),
    $regex, _desc($desc, qq{no similar match for attribute "$attribute" at selector "$selector"}));
}

sub content_is {
  my ($self, $value, $desc) = @_;
  return $self->_test('is', $self->tx->res->text,
    $value, _desc($desc, 'exact match for content'));
}

sub content_isnt {
  my ($self, $value, $desc) = @_;
  return $self->_test('isnt', $self->tx->res->text,
    $value, _desc($desc, 'no match for content'));
}

sub content_like {
  my ($self, $regex, $desc) = @_;
  return $self->_test('like', $self->tx->res->text,
    $regex, _desc($desc, 'content is similar'));
}

sub content_type_is {
  my ($self, $type, $desc) = @_;
  $desc = _desc($desc, "Content-Type: $type");
  return $self->_test('is', $self->tx->res->headers->content_type, $type,
    $desc);
}

sub content_type_isnt {
  my ($self, $type, $desc) = @_;
  $desc = _desc($desc, "not Content-Type: $type");
  return $self->_test('isnt', $self->tx->res->headers->content_type, $type,
    $desc);
}

sub content_type_like {
  my ($self, $regex, $desc) = @_;
  $desc = _desc($desc, 'Content-Type is similar');
  return $self->_test('like', $self->tx->res->headers->content_type, $regex,
    $desc);
}

sub content_type_unlike {
  my ($self, $regex, $desc) = @_;
  $desc = _desc($desc, 'Content-Type is not similar');
  return $self->_test('unlike', $self->tx->res->headers->content_type, $regex,
    $desc);
}

sub content_unlike {
  my ($self, $regex, $desc) = @_;
  return $self->_test('unlike', $self->tx->res->text,
    $regex, _desc($desc, 'content is not similar'));
}

sub delete_ok { shift->_build_ok(DELETE => @_) }

sub element_count_is {
  my ($self, $selector, $count, $desc) = @_;
  my $size = $self->tx->res->dom->find($selector)->size;
  return $self->_test('is', $size, $count,
    _desc($desc, qq{element count for selector "$selector"}));
}

sub element_exists {
  my ($self, $selector, $desc) = @_;
  $desc = _desc($desc, qq{element for selector "$selector" exists});
  return $self->_test('ok', $self->tx->res->dom->at($selector), $desc);
}

sub element_exists_not {
  my ($self, $selector, $desc) = @_;
  $desc = _desc($desc, qq{no element for selector "$selector"});
  return $self->_test('ok', !$self->tx->res->dom->at($selector), $desc);
}

sub finish_ok {
  my $self = shift;
  $self->tx->finish(@_) if $self->tx->is_websocket;
  Mojo::IOLoop->one_tick while !$self->{finished};
  return $self->_test('ok', 1, 'closed WebSocket');
}

sub finished_ok {
  my ($self, $code) = @_;
  Mojo::IOLoop->one_tick while !$self->{finished};
  Test::More::diag "WebSocket closed with status $self->{finished}[0]"
    unless my $ok = $self->{finished}[0] == $code;
  return $self->_test('ok', $ok, "WebSocket closed with status $code");
}

sub get_ok  { shift->_build_ok(GET  => @_) }
sub head_ok { shift->_build_ok(HEAD => @_) }

sub header_exists {
  my ($self, $name, $desc) = @_;
  $desc = _desc($desc, qq{header "$name" exists});
  return $self->_test('ok', !!@{$self->tx->res->headers->every_header($name)},
    $desc);
}

sub header_exists_not {
  my ($self, $name, $desc) = @_;
  $desc = _desc($desc, qq{no "$name" header});
  return $self->_test('ok', !@{$self->tx->res->headers->every_header($name)},
    $desc);
}

sub header_is {
  my ($self, $name, $value, $desc) = @_;
  $desc = _desc($desc, "$name: " . ($value // ''));
  return $self->_test('is', $self->tx->res->headers->header($name), $value,
    $desc);
}

sub header_isnt {
  my ($self, $name, $value, $desc) = @_;
  $desc = _desc($desc, "not $name: " . ($value // ''));
  return $self->_test('isnt', $self->tx->res->headers->header($name), $value,
    $desc);
}

sub header_like {
  my ($self, $name, $regex, $desc) = @_;
  $desc = _desc($desc, "$name is similar");
  return $self->_test('like', $self->tx->res->headers->header($name), $regex,
    $desc);
}

sub header_unlike {
  my ($self, $name, $regex, $desc) = @_;
  $desc = _desc($desc, "$name is not similar");
  return $self->_test('unlike', $self->tx->res->headers->header($name),
    $regex, $desc);
}

sub json_has {
  my ($self, $p, $desc) = @_;
  $desc = _desc($desc, qq{has value for JSON Pointer "$p"});
  return $self->_test('ok',
    !!Mojo::JSON::Pointer->new($self->tx->res->json)->contains($p), $desc);
}

sub json_hasnt {
  my ($self, $p, $desc) = @_;
  $desc = _desc($desc, qq{has no value for JSON Pointer "$p"});
  return $self->_test('ok',
    !Mojo::JSON::Pointer->new($self->tx->res->json)->contains($p), $desc);
}

sub json_is {
  my $self = shift;
  my ($p, $data) = @_ > 1 ? (shift, shift) : ('', shift);
  my $desc = _desc(shift, qq{exact match for JSON Pointer "$p"});
  return $self->_test('is_deeply', $self->tx->res->json($p), $data, $desc);
}

sub json_like {
  my ($self, $p, $regex, $desc) = @_;
  return $self->_test('like', $self->tx->res->json($p),
    $regex, _desc($desc, qq{similar match for JSON Pointer "$p"}));
}

sub json_message_has {
  my ($self, $p, $desc) = @_;
  $desc = _desc($desc, qq{has value for JSON Pointer "$p"});
  return $self->_test('ok', $self->_json(contains => $p), $desc);
}

sub json_message_hasnt {
  my ($self, $p, $desc) = @_;
  $desc = _desc($desc, qq{has no value for JSON Pointer "$p"});
  return $self->_test('ok', !$self->_json(contains => $p), $desc);
}

sub json_message_is {
  my $self = shift;
  my ($p, $data) = @_ > 1 ? (shift, shift) : ('', shift);
  my $desc = _desc(shift, qq{exact match for JSON Pointer "$p"});
  return $self->_test('is_deeply', $self->_json(get => $p), $data, $desc);
}

sub json_message_like {
  my ($self, $p, $regex, $desc) = @_;
  return $self->_test('like', $self->_json(get => $p),
    $regex, _desc($desc, qq{similar match for JSON Pointer "$p"}));
}

sub json_message_unlike {
  my ($self, $p, $regex, $desc) = @_;
  return $self->_test('unlike', $self->_json(get => $p),
    $regex, _desc($desc, qq{no similar match for JSON Pointer "$p"}));
}

sub json_unlike {
  my ($self, $p, $regex, $desc) = @_;
  return $self->_test('unlike', $self->tx->res->json($p),
    $regex, _desc($desc, qq{no similar match for JSON Pointer "$p"}));
}

sub message_is {
  my ($self, $value, $desc) = @_;
  return $self->_message('is', $value, _desc($desc, 'exact match for message'));
}

sub message_isnt {
  my ($self, $value, $desc) = @_;
  return $self->_message('isnt', $value, _desc($desc, 'no match for message'));
}

sub message_like {
  my ($self, $regex, $desc) = @_;
  return $self->_message('like', $regex, _desc($desc, 'message is similar'));
}

sub message_ok {
  my ($self, $desc) = @_;
  return $self->_test('ok', !!$self->_wait, _desc($desc, 'message received'));
}

sub message_unlike {
  my ($self, $regex, $desc) = @_;
  return $self->_message('unlike', $regex,
    _desc($desc, 'message is not similar'));
}

sub new {
  my $self = shift->SUPER::new;
  
  return $self unless my $app = shift;
  
  my @args = @_ ? {config => {config_override => 1, %{shift()}}} : ();
  return $self->app(Mojo::Server->new->build_app($app, @args)) unless ref $app;
  $app = Mojo::Server->new->load_app($app) unless $app->isa('Mojolicious');
  return $self->app(@args ? $app->config($args[0]{config}) : $app);
}

sub options_ok { shift->_build_ok(OPTIONS => @_) }

sub or {
  my ($self, $cb) = @_;
  $self->$cb unless $self->success;
  return $self;
}

sub patch_ok { shift->_build_ok(PATCH => @_) }
sub post_ok  { shift->_build_ok(POST  => @_) }
sub put_ok   { shift->_build_ok(PUT   => @_) }

sub request_ok { shift->_request_ok($_[0], $_[0]->req->url->to_string) }

sub reset_session {
  my $self = shift;
  $self->ua->cookie_jar->empty;
  return $self->tx(undef);
}

sub send_ok {
  my ($self, $msg, $desc) = @_;
  
  $desc = _desc($desc, 'send message');
  return $self->_test('ok', 0, $desc) unless $self->tx->is_websocket;
  
  $self->tx->send($msg => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  return $self->_test('ok', 1, $desc);
}

sub status_is {
  my ($self, $status, $desc) = @_;
  $desc = _desc($desc, "$status " . $self->tx->res->default_message($status));
  return $self->_test('is', $self->tx->res->code, $status, $desc);
}

sub status_isnt {
  my ($self, $status, $desc) = @_;
  return $self->_test('isnt', $self->tx->res->code,
    $status,
    _desc($desc, "not $status " . $self->tx->res->default_message($status)));
}

sub text_is {
  my ($self, $selector, $value, $desc) = @_;
  return $self->_test('is', $self->_text($selector),
    $value, _desc($desc, qq{exact match for selector "$selector"}));
}

sub text_isnt {
  my ($self, $selector, $value, $desc) = @_;
  return $self->_test('isnt', $self->_text($selector),
    $value, _desc($desc, qq{no match for selector "$selector"}));
}

sub text_like {
  my ($self, $selector, $regex, $desc) = @_;
  return $self->_test('like', $self->_text($selector),
    $regex, _desc($desc, qq{similar match for selector "$selector"}));
}

sub text_unlike {
  my ($self, $selector, $regex, $desc) = @_;
  return $self->_test('unlike', $self->_text($selector),
    $regex, _desc($desc, qq{no similar match for selector "$selector"}));
}

sub websocket_ok {
  my $self = shift;
  return $self->_request_ok($self->ua->build_websocket_tx(@_), $_[0]);
}

sub _attr {
  my ($self, $selector, $attribute) = @_;
  return '' unless my $e = $self->tx->res->dom->at($selector);
  return '' unless my $attr_value = $e->attr($attribute);
  return $attr_value;
}

sub _build_ok {
  my ($self, $method, $url) = (shift, shift, shift);
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  return $self->_request_ok($self->ua->build_tx($method, $url, @_), $url);
}

sub _desc { encode 'UTF-8', shift || shift }

sub _json {
  my ($self, $method, $p) = @_;
  return Mojo::JSON::Pointer->new(j(@{$self->message // []}[1]))->$method($p);
}

sub _message {
  my ($self, $name, $value, $desc) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my ($type, $msg) = @{$self->message // []};
  
  # Type check
  if (ref $value eq 'HASH') {
    my $expect = exists $value->{text} ? 'text' : 'binary';
    $value = $value->{$expect};
    $msg   = '' unless ($type // '') eq $expect;
  }
  
  # Decode text frame if there is no type check
  else { $msg = decode 'UTF-8', $msg if ($type // '') eq 'text' }
  
  return $self->_test($name, $msg // '', $value, $desc);
}

sub _request_ok {
  my ($self, $tx, $url) = @_;
  
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  
  # Establish WebSocket connection
  if ($tx->req->is_handshake) {
    @$self{qw(finished messages)} = (undef, []);
    $self->ua->start(
      $tx => sub {
        my ($ua, $tx) = @_;
        $self->{finished} = [] unless $self->tx($tx)->tx->is_websocket;
        $tx->on(finish => sub { shift; $self->{finished} = [@_] });
        $tx->on(binary => sub { push @{$self->{messages}}, [binary => pop] });
        $tx->on(text   => sub { push @{$self->{messages}}, [text   => pop] });
        Mojo::IOLoop->stop;
      }
    );
    Mojo::IOLoop->start;
    
    my $desc = _desc("WebSocket handshake with $url");
    return $self->_test('ok', $self->tx->is_websocket, $desc);
  }
  
  # Perform request
  $self->tx($self->ua->start($tx));
  my $err = $self->tx->error;
  Test::More::diag $err->{message}
    if !(my $ok = !$err->{message} || $err->{code}) && $err;
  return $self->_test('ok', $ok, _desc("@{[uc $tx->req->method]} $url"));
}

sub _test {
  my ($self, $name, @args) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 2;
  return $self->success(!!Test::More->can($name)->(@args));
}

sub _text {
  return '' unless my $e = shift->tx->res->dom->at(shift);
  return $e->text;
}

sub _wait {
  my $self = shift;
  Mojo::IOLoop->one_tick while !$self->{finished} && !@{$self->{messages}};
  return $self->message(shift @{$self->{messages}})->message;
}

1;
