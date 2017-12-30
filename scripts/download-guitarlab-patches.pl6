#!/usr/bin/env perl6
#
# Zoom Guitar Lab Patch download script.
# This script will scrape the Zoom download
# page for Guitar Lab Patch data zip files,
# download the files, then save the files in
# target output directory.
#
# The script will skip files that already exist.
# To re-download a file simply delete it from the 
# target directory or provide a new target directory.
# 
# Usage:
#
# ./scripts/download-guitarlab-patches.pl6 --model=g3xn --out=/path/to/save/patches
#
# Defautls
#
# --out   = ~/Zoom-Patches/{model}
# --model = g3xn
#
# Options
#
# Use --url to download from a direct link (must provide a model name):
#
# ./scripts/download-guitarlab-patches.pl6 \
#     --model=specialmodel \
#     --url=https://www.zoom.co.jp/products/guitar-bass-effects/bass/b3n-multi-effects-processor#downloads

use v6;

use Cro::HTTP::Client;

sub download(
    IO::Path :$out = $*HOME.IO.child('Zoom-Patches'),
    Str      :$model,
    Str      :$url
) {

    my %urls = %{
        g3xn => 'https://www.zoom.co.jp/products/guitar-bass-effects/guitar/g3xn-multi-effects-processor#downloads',
        g3n  => 'https://www.zoom.co.jp/products/guitar-bass-effects/guitar/g3n-multi-effects-processor#downloads',
        gn5  => 'https://www.zoom.co.jp/products/guitar-bass-effects/guitar/g5n-multi-effects-processor#downloads',
        b3n  => 'https://www.zoom.co.jp/products/guitar-bass-effects/bass/b3n-multi-effects-processor#downloads'
    }

    # Create output directory
    mkdir $out.child($model);
    die "Output directory not found" unless $out.child($model).IO ~~ :e;

    my $client = Cro::HTTP::Client.new;
    my $resp   = await $client.get: ($url ?? $url !! %urls{$model});
    my $html   = await $resp.body-text();
    my @download_urls = ~<< ($html ~~ m:g/ 'href="' <(\S* 'ZoomGuitarLab_Patch_Data' \S*)> '"'/);

    map -> $url {
        my $file_name = S/<["]>// given split('/', $url).tail;
        my $target    = $out.child($model).child($file_name); 
        next when $target.IO ~~ :e;
        say "Downloading $file_name";
        my $resp      = await $client.get: $url;
        spurt $out.child($model).child($file_name), await $resp.body-blob();
    }, @download_urls;
}

multi sub MAIN(
    IO::Path :$out = $*HOME.IO.child('Zoom-Patches'),
    Str      :$model = 'g3xn'
) {
    download :$out, :$model;
}

multi sub MAIN(
    IO::Path :$out = $*HOME.IO.child('Zoom-Patches'),
    Str      :$model!, # must supply a model name when using url
    Str      :$url!
) {
    download :$out, :$model, :$url;
}
