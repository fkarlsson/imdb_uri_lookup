# 
# IMDb Irssi plugin 
# Decode and print information from IMDb URIs 
# 

# 
# Changes 
# 0.1 First version!
# 1.0 First stable
# 1.1 LITET B

use strict; 
use Irssi; 
use JSON;
use feature qw(switch say);

use Irssi::Irc; 
use LWP::UserAgent; 
use vars qw($VERSION %IRSSI);

$VERSION = '1.1'; 
%IRSSI = ( 
    authors     => 'Fredrik Karlsson', 
    contact     => 'fkarlsson@gmail.com', 

    name        => 'imdb_uri_lookup', 
    description => 'Lookup IMDb URIs and output info to proper window.', 
    license     => '', 
    url         => '', 
); 

sub imdburi_public { 
    my ($server, $data, $nick, $mask, $target) = @_; 
    my $retval = imdburi_get($data); 
    my $win = $server->window_item_find($target); 
    Irssi::signal_continue(@_);

    if ($win) { 
        $win->print("%_IMDb:%_ $retval", MSGLEVEL_CRAP) if $retval; 
    } else { 
        Irssi::print("%_IMDb:%_ $retval") if $retval; 
    } 
} 
sub imdburi_private { 
    my ($server, $data, $nick, $mask) = @_; 
    my $retval = imdburi_get($data); 
    my $win = Irssi::window_find_name('(msgs)'); 
    Irssi::signal_continue(@_);

    if ($win) { 
        $win->print("%_IMDb:%_ $retval", MSGLEVEL_CRAP) if $retval; 
    } else { 
        Irssi::print("%_IMDb:%_ $retval") if $retval; 
    } 
} 
sub imdburi_parse { 
    my ($url) = @_; 
    if ($url =~ /(http:\/\/imdb.com\/|http:\/\/www.imdb.com\/)(title)\/(tt)([0-9]+)\/?/) { 
        return "http://www.imdbapi.com/?i=$3$4";
    } 
    return 0; 
} 
sub imdburi_get { 
    my ($data) = @_; 

    my $url = imdburi_parse($data);

    my $ua = LWP::UserAgent->new(env_proxy=>1, keep_alive=>1, timeout=>5); 
    $ua->agent("irssi/$VERSION " . $ua->agent()); 

    my $req = HTTP::Request->new('GET', $url); 
    my $res = $ua->request($req);

    if ($res->is_success()) { 
        my $json = JSON->new->utf8;
        my $json_data = $json->decode($res->content());
        my $result_string = '';

        # If the API implements names sometime, I'm prepared
        my $type = 'title';
        given ($type) {
            when ('title') {
                my $rating = '';
                if ($json_data->{Rating} != 'N/A')
                {
                    $rating = "- $json_data->{Rating} ";
                }
                $result_string = "$json_data->{Title} $rating%K[%n$json_data->{Year}%K]%n";
            }
            default {
                $result_string = 'Error';
            }
        }

        return $result_string; 
    } 
    return 0; 
} 

Irssi::signal_add_last('message public', 'imdburi_public'); 
Irssi::signal_add_last('message private', 'imdburi_private'); 