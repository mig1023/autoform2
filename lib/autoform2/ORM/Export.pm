package autoform2::ORM::Export;

use utf8;
use Exporter;

@ISA = qw( Exporter );
our @EXPORT = qw( create_new_appointment create_table mod_hash  );

sub create_new_appointment
# //////////////////////////////////////////////////
{
	my $self = shift;
	
	my $info_for_contract = "from_db";
	
	my $tables_transfered_id = $self->get_current_table_id();

	my $db_rules = $self->get_content_db_rules();

	my $ver = $self->get_app_version();

	my $data_for_contract = $self->db->query( "
		SELECT CenterID, PersonForAgreements
		FROM AutoToken
		JOIN AutoAppointments ON AutoToken.AutoAppID = AutoAppointments.ID
		WHERE Token = ?", $self->{ token }
	)->[ 0 ];
	
	if ( $data_for_contract->{ PersonForAgreements } != -1 ) {
	
		$info_for_contract = $self->db->query( "
			SELECT RLName as LName, RFName as FName, RMName as MName, RPassNum as PassNum, 
			RPWhen as PassDate, RPWhere as PassWhom, AppPhone as Phone, RAddress as Address 
			FROM AutoAppData WHERE ID = ?", $data_for_contract->{ PersonForAgreements }
		)->[ 0 ];
	}

	# my $time_start = $self->time_interval_calculate();
	
	$self->db->query( "
		LOCK TABLES
		AutoAppointments READ, Appointments WRITE, AutoAppData READ, AppData WRITE,
		AutoSchengenAppData READ, SchengenAppData WRITE, AutoSpbAlterAppData READ,
		SpbAlterAppData WRITE, AutoSchengenExtData READ, Countries READ"
	);
	
	my $new_appid = $self->create_table(
		'AutoAppointments', 'Appointments', $tables_transfered_id->{ AutoAppointments },
		$db_rules, undef, undef, $info_for_contract, undef, $ver
	);
	
	if ( !$new_appid ) {
	
		$self->query( 'query', __LINE__, "UNLOCK TABLES");
		
		return ( 0, 0, 0, "new appointment error" );
	}

	my $allapp = $self->db->query( "
		SELECT AutoAppData.ID, SchengenAppDataID, AutoSpbAlterAppData.ID as SpbID
		FROM AutoAppData
		JOIN AutoSpbAlterAppData ON AutoSpbAlterAppData.AppDataID = AutoAppData.ID
		WHERE AppID = ?", 
		$tables_transfered_id->{ 'AutoAppointments' }
	);
	
	for my $app ( @$allapp ) {
		
		my $sch_appid = $self->create_table(
			'AutoSchengenAppData', 'SchengenAppData', $app->{ SchengenAppDataID }, $db_rules
		);
		
		my $appid = $self->create_table(
			'AutoAppData', 'AppData', $app->{ ID }, $db_rules, $new_appid, $sch_appid, undef,
			$data_for_contract->{ CenterID }, undef, $app->{ SchengenAppDataID }
		);
		
		$self->create_table(
			'AutoSpbAlterAppData', 'SpbAlterAppData', $app->{ SpbID }, $db_rules, $appid
		);
	}
	
	$self->query( 'query', __LINE__, "UNLOCK TABLES");
	
	my $appnum = $self->db->query( "
		SELECT AppNum FROM Appointments WHERE ID = ?", $new_appid
	);

	return ( $new_appid, scalar @$allapp, $appnum );
}

sub create_table
# //////////////////////////////////////////////////
{
	my ( $self, $autoname, $name, $transfered_id, $db_rules, $new_appid, $sch_appid,
		$info_for_contract, $center, $ver, $sch_auto ) = @_;

	my $hash = $self->get_hash_table( $autoname, 'ID', $transfered_id );

	$hash = $self->mod_hash(
		$hash, $name, $db_rules, $new_appid, $sch_appid, $info_for_contract, $center, $ver, $sch_auto
	);

	return $self->insert_hash_table( $name, $hash );
}

sub mod_hash
# //////////////////////////////////////////////////
{
	my ( $self, $hash, $table_name, $db_rules, $appid, $schappid, $info_for_contract,
		$center, $ver, $sch_auto ) = @_;

	for my $column ( keys %$hash ) {

		if ( $db_rules->{ $table_name }->{ $column } eq 'nope') {
			delete $hash->{ $column };
		}
	};
	
	$hash = $self->visapurpose_assembler( $hash ) if exists $hash->{ VisaPurpose };
	
	$hash = $self->mezzi_assembler( $hash ) if exists $hash->{ Mezzi1 };
	
	if ( $hash->{ ShIndex } ) {
	
		$hash->{ Shipping } = 1;
		$hash->{ ShAddress } = $hash->{ ShIndex } . ", " . $hash->{ ShAddress };
	}
	
	$hash->{ SMS } = 1 if $hash->{ Mobile };
	$hash->{ AppID } = $appid if $appid;
	$hash->{ SchengenAppDataID } = $schappid if $schappid;
	$hash->{ Status } = 1 if exists $hash->{ Status };
	
	if ( $table_name eq 'AppData' ) {
	
		my $schengen_data = $self->get_hash_table( 'AutoSchengenAppData', 'ID', $sch_auto );
		
		if ( $schengen_data->{ HostDataType } eq 'P' ) {
		
			$hash->{ Hotels } = $schengen_data->{ HostDataName } . ' ' . $schengen_data->{ HostDataDenomination };
	
			$hash->{ HotelAdresses } = join( ', ', ($schengen_data->{ HostDataCity },
				$schengen_data->{ HostDataAddress }, $schengen_data->{ HostDataEmail }
			) );
			
			$hash->{ HotelPhone } = $schengen_data->{ HostDataPhoneNumber };
		}
		
		$hash->{ NRes } = ( $hash->{ Citizenship } == 70 ? 0 : 1 ) ;
		
		$hash->{ CountryLive } = ( $hash->{ NRes } ? 1 : 0 );
		
		$hash->{ PrevVisa }--;
		
		if ( VCS::Site::autodata::this_is_spb_center( $center ) ) {
		
			$hash->{ Countries } = 133; 
		
			my $spb_hash = $self->get_hash_table( 'AutoSpbAlterAppData', 'AppDataID', $hash->{ ID } );

			$hash->{ WorkOrg } = join( ', ', (
				$spb_hash->{ JobName }, $spb_hash->{ JobCity }, $spb_hash->{ JobAddr }, $spb_hash->{ JobPhone }
			) );
	
			$hash->{ FullAddress } = join( ', ', (
				$spb_hash->{ HomeCity }, $spb_hash->{ HomeAddr }, $spb_hash->{ HomeEmail }
			) );
					
			$hash->{ HotelAdresses } = join( ', ', (
				$spb_hash->{ HotelPostCode }, $spb_hash->{ HotelCity }, $spb_hash->{ HotelStreet }, $spb_hash->{ HotelHouse }
			) ) unless $hash->{ HotelAdresses };
		
			unless ( $hash->{ Hotels } ) {
			
				$hash->{ Hotels } = $spb_hash->{ HotelName } || '';
			}
		}
		else {
			my $ext_data = $self->get_hash_table( 'AutoSchengenExtData', 'AppDataID', $hash->{ ID } );
	
			$ext_data->{ AppEMail } = $hash->{ AppEMail };
			
			$hash->{ SchengenJSON } = JSON->new->pretty->encode( $ext_data );
			
			$hash->{ FullAddress } = join( ', ', (
				$ext_data->{ HomeCity }, $ext_data->{ HomeAddress },
				$ext_data->{ HomePostal }, $hash->{ AppEMail }
			) );
			
			if ( $ext_data->{ Occupation } eq 'ALTRE PROFESSIONI' ) {
			
				$hash->{ ProfActivity } = $hash->{ ProfActivity } || 'ALTRE PROFESSIONI';
			}
			else {
				$hash->{ ProfActivity } = $ext_data->{ Occupation } || $hash->{ ProfActivity } || 'ALTRE PROFESSIONI';
			}

			$hash->{ WorkOrg } = join( ', ', (
				$ext_data->{ JobName }, $ext_data->{ JobCity }, $ext_data->{ JobAddress },
				$ext_data->{ JobPostal }, $ext_data->{ JobPhone }, $ext_data->{ JobEmail }
			) );
			
			$hash->{ KinderData } = join( ' ', (
				$ext_data->{ MotherName }, $ext_data->{ MotherSurname },
				$self->countries( $ext_data->{ MotherCitizenship } ), ', ',
				$ext_data->{ FatherName }, $ext_data->{ FatherSurname },
				$self->countries( $ext_data->{ FatherCitizenship } ), 
			) );
			
			$hash->{ KinderData } =~ s/^\s*,\s*$//;
			
			$hash->{ ACopmanyPerson } = join( ' ', ( $ext_data->{ InvitName }, $ext_data->{ InvitSurname }	) );

			if ( ( $schengen_data->{ HostDataType } =~ /^(H|S)$/i ) && ( $ext_data->{ HotelAddress } !~ /^\s*$/ ) ) {

				$hash->{ HotelAdresses } = $ext_data->{ HotelCity } if $ext_data->{ HotelCity };
				$hash->{ HotelAdresses } .= ', ' if $ext_data->{ HotelCity } and $ext_data->{ HotelAddress };
				$hash->{ HotelAdresses } .= $ext_data->{ HotelAddress } if $ext_data->{ HotelAddress };
			}
		}
	}

	if ( $table_name eq 'Appointments' ) {
	
		my $appointments = VCS::Docs::appointments->new('VCS::Docs::appointments', $self->{ vars } );
		
		$hash->{ AppNum } = $appointments->getLastAppNum( $self->{ vars }, $hash->{ CenterID }, $hash->{ AppDate } );
		
		$hash->{ OfficeToReceive } = ( $hash->{ OfficeToReceive } == 2 ? 39 : undef ) ;
		
		$hash->{ Notes } = $ver;
		
		if ( ref( $info_for_contract ) eq 'HASH' ) {

			$hash->{ dwhom } = 0;
		
			$hash->{ $_ } = $info_for_contract->{ $_ } for ( keys %$info_for_contract );
		}
		else {
			$hash->{ dwhom } = 1;
		}
	}
	
	delete $hash->{ $_ } for ( 'ShIndex', 'ID', 'FinishedVType', 'FinishedCenter', 'AppEMail',
		'AppDataID', 'PrimetimeAlert', 'Copypasta' );
		
	return $hash;
}

1;