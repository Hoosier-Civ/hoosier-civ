// Types derived from the Cicero v3.1 /official API response.

export interface CiceroResponse {
  response: {
    errors: unknown[];
    messages: unknown[];
    results: {
      candidates: CiceroCandidate[];
    };
  };
}

export interface CiceroCandidate {
  count: {
    from: number;
    to: number;
    total: number;
  };
  officials: CiceroOfficial[];
  locator: string;
  score: number;
  match_addr: string;
  match_city: string;
  match_subregion: string;
  match_region: string;   // e.g. "IN" — state abbreviation
  match_postal: string;
  match_country: string;
  match_streetaddr: string;
  x: number;             // longitude
  y: number;             // latitude
  wkid: number;
  locator_type: string;
  geoservice: string;
}

export interface CiceroOfficial {
  id: number;
  sk: number;
  valid_from: string;
  valid_to: string | null;
  last_update_date: string;
  salutation: string;
  first_name: string;
  middle_initial: string;
  last_name: string;
  nickname: string;
  preferred_name: string;
  name_suffix: string;
  party: string;
  photo_origin_url: string | null;
  photo_cropping: unknown | null;
  web_form_url: string;
  urls: string[];
  initial_term_start_date: string | null;
  current_term_start_date: string | null;
  term_end_date: string | null;
  /** notes[0] is a biography string; notes[1] is a birth date string or null */
  notes: (string | null)[];
  titles: unknown[];
  email_addresses: string[];
  addresses: CiceroAddress[];
  committees: CiceroCommittee[];
  identifiers: CiceroIdentifier[];
  office: CiceroOffice;
}

export interface CiceroAddress {
  address_1: string;
  address_2: string;
  address_3: string;
  city: string;
  county: string;
  state: string;
  postal_code: string;
  phone_1: string;
  fax_1: string;
  phone_2: string;
  fax_2: string;
}

export interface CiceroCommittee {
  name: string;
  urls: string[];
  committee_identifiers: CiceroCommitteeIdentifier[];
  position: string;
}

export interface CiceroCommitteeIdentifier {
  id: number;
  identifier_type: string;
  identifier_value: string;
}

export interface CiceroIdentifier {
  id: number;
  sk: number;
  official: number;
  version: number;
  identifier_type: CiceroIdentifierType;
  identifier_value: string;
  valid_from: string;
  valid_to: string | null;
  last_update_date: string;
}

export type CiceroIdentifierType =
  | "BIOGUIDE"
  | "CRP"
  | "FACEBOOK"
  | "FACEBOOK-CAMPAIGN"
  | "FACEBOOK-OFFICIAL"
  | "FEC"
  | "GOVTRACK"
  | "GOVTRACK-COMMITTEE"
  | "INSTAGRAM"
  | "INSTAGRAM-CAMPAIGN"
  | "LINKEDIN"
  | "TWITTER"
  | "VOTESMART"
  | "YOUTUBE"

export interface CiceroOffice {
  id: number;
  sk: number;
  valid_from: string;
  valid_to: string | null;
  last_update_date: string;
  title: string;
  notes: string;
  election_rules: string;
  representing_city: string;
  representing_state: string;
  representing_country: CiceroCountry;
  district: CiceroDistrict;
  chamber: CiceroChamber;
}

export interface CiceroDistrict {
  id: number;
  sk: number;
  valid_from: string;
  valid_to: string | null;
  last_update_date: string;
  district_type: CiceroDistrictType;
  subtype: string;
  country: string;
  state: string;
  city: string;
  district_id: string;
  label: string;
  num_officials: number;
  ocd_id: string | null;
  data: Record<string, unknown>;
}

export type CiceroDistrictType =
  | "NATIONAL_EXEC"
  | "NATIONAL_LOWER"
  | "NATIONAL_UPPER"
  | "STATE_EXEC"
  | "STATE_LOWER"
  | "STATE_UPPER"
  | "LOCAL"
  | "LOCAL_EXEC"

export interface CiceroChamber {
  id: number;
  name: string;
  name_formal: string;
  name_native_language: string;
  type: "UPPER" | "LOWER" | "EXEC" | (string & Record<never, never>);
  official_count: number;
  term_length: string;
  term_limit: string;
  election_frequency: string;
  election_rules: string;
  inauguration_rules: string;
  redistricting_rules: string;
  vacancy_rules: string;
  remarks: string;
  notes: string;
  url: string;
  contact_phone: string;
  contact_email: string;
  is_chamber_complete: boolean;
  is_appointed: boolean;
  has_geographic_representation: boolean;
  legislature_update_date: string | null;
  last_update_date: string;
  government: CiceroGovernment;
}

export interface CiceroGovernment {
  name: string;
  type: string;
  city: string;
  state: string;
  notes: string;
  country: CiceroCountry;
}

export interface CiceroCountry {
  id: number;
  sk: number;
  version: number;
  fips: string;
  iso_2: string;
  iso_3: string;
  iso_3_numeric: number;
  gmi_3: string;
  name_short: string;
  name_short_iso: string;
  name_short_local: string;
  name_short_un: string;
  name_long: string;
  name_long_local: string;
  status: string;
  valid_from: string;
  valid_to: string | null;
  last_update_date: string;
}
