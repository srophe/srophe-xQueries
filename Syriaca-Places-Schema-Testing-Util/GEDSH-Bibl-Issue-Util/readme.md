# Overview of Directory Contents

This directory contains scripts that were used to:

   1. Add the [e-GEDSH](gedsh.bethmardutho.org/) article URIs to the associated [Syriaca bibl](http://syriaca.org/bibl/index.html) records
   2. Update the tei:bibl/ptr/@target attribute values in Syriaca entity records that pointed to the GEDSH monograph with article-specific URIs.

As this change has been made in all data, these scripts will likely not need to be used again.

However, the CSV file, "gedsh-bibl-subject-uri-associated.csv" may be of interest in future. This file aligns the following data:
- the GEDSH entry number (e.g. 183, for Edessa)
- the GEDSH entry headword (e.g. Edessa)
- the e-GEDSH URI (e.g. https://gedsh.bethmardutho.org/Edessa)
- the Syriaca Bibl URI for the GEDSH article (e.g., http://syriaca.org/bibl/192 for Edessa)
- The Syriaca entity URI that is the subject of the GEDSH article (e.g. http://syriaca.org/place/78 for Edessa)
- the entity type described by the GEDSH article (e.g. "place" for Edessa)
