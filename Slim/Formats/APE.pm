package Slim::Formats::APE;

# $tagsd: APE.pm,v 1.0 2004/01/27 00:00:00 daniel Exp $
# $Id: APE.pm,v 1.1 2005/01/02 22:28:08 kdf Exp $

# SlimServer Copyright (c) 2001-2004 Sean Adams, Slim Devices Inc.
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License,
# version 2.

###############################################################################
# FILE: Slim::Formats::Musepack.pm
#
# DESCRIPTION:
#   Extract APE tag information from a Monkey's Audio file and store in a hash for 
#   easy retrieval.
#
###############################################################################

use strict;
use Audio::APETags;
use Audio::APE;
use MP3::Info ();

my %tagMapping = (
	'TRACK'	=> 'TRACKNUM',
	'DATE'		=> 'YEAR',
	'DISCNUMBER'	=> 'DISC',
);

# Given a file, return a hash of name value pairs,
# where each name is a tag name.
sub getTag {

	my $file = shift || "";

	my $mac = Audio::APE->new($file);

	my $tags = $mac->tags() || {};

	# Check for the presence of the info block here
	unless (defined $mac->{'bitRate'}) {
		return undef;
	}

	# There should be a TITLE tag if the APE tags are to be trusted
	if (defined $tags->{'TITLE'}) {

		# map the existing tag names to the expected tag names
		while (my ($old,$new) = each %tagMapping) {
			if (exists $tags->{$old}) {
				$tags->{$new} = $tags->{$old};
				delete $tags->{$old};
			}
		}
	}

	# add more information to these tags
	# these are not tags, but calculated values from the streaminfo
	$tags->{'SIZE'}    = $mac->{'fileSize'};
	$tags->{'BITRATE'} = $mac->{'bitRate'};
	$tags->{'SECS'} = $mac->{'duration'};
#	$tags->{'OFFSET'}  = $mac->{'startAudioData'};

	# Add the stuff that's stored in the Streaminfo Block
	#my $mpcInfo = $mac->info();
	$tags->{'RATE'}     = $mac->{'sampleRate'};
	$tags->{'CHANNELS'} = $mac->{'Channels'};

	# stolen from MP3::Info
	$tags->{'MM'}	    = int $tags->{'SECS'} / 60;
	$tags->{'SS'}	    = int $tags->{'SECS'} % 60;
	$tags->{'MS'}	    = (($tags->{'SECS'} - ($tags->{'MM'} * 60) - $tags->{'SS'}) * 1000);
	$tags->{'TIME'}	    = sprintf "%.2d:%.2d", @{$tags}{'MM', 'SS'};

	return $tags;
}

1;
