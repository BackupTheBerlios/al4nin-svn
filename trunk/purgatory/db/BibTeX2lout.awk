# Usage : awk -f BibTeX2lout.awk < BibTexDB > acmrefs.ld
#

# Here is the complete set of values that you may give to the @Type option:
# Book TechReport Article InBook
# Proceedings MastersThesis InProceedings
# PhDThesis MiscP

# /Book.*=.*/ {print "Book { " $4 " }"; next}
/@book[ \t]*{.*/ {print "{ @Reference\n   @Type { Book }"; have = 1; next}
# /Booklet.*=.*/ {print "Book { " $4 " }"; next}
# /Proceedings.*=.*/ {print "Proceedings { " $4 " }"; next}
# /Conference.*=.*/ {print "Proceedings { " $4 " }"; next}
# /PhdThesis.*=.*/ {print "PhDThesis { " $4 " }"; next}
# /TechReport.*=.*/ {print "TechReport { " $4 " }"; next}
/@techreport[ \t]*{.*/ {print "{ @Reference\n   @Type { TechReport }"; have = 1; next}
# /Manual.*=.*/ {print "TechReport { " $4 " }"; next}
# /MastersThesis.*=.*/ {print "MastersThesis { " $4 " }"; next}
# /Misc.*=.*/ {print "Misc { " $4 " }"; next}
# /Unpublished.*=.*/ {print "Misc { " $4 " }"; next}
# /Article.*=.*/ {print "Article { " $4 " }"; next}
/@article[ \t]*{.*/ {print "{ @Reference\n   @Type { Article }"; have = 1; next}
# /InBook.*=.*/ {print "InBook { " $4 " }"; next}
# /InCollection.*=.*/ {print "InBook { " $4 " }"; next}
/@inproceedings[ \t]*{.*/ {print "{ @Reference\n   @Type { InProceedings }"; have = 1; next}

{ split($0, arr, "{"); split(arr[2], brr, "}"); cont = brr[1] }

/typ.*=.*/ {print "   @Type { " cont " }"; next}
/tag.*=.*/ {print "   @Tag { " cont " }"; next}
# /.*=.*/ {print "   @Abstract { " cont " }"; next}
/address.*=.*/ {print "   @Address { " cont " }"; next}
/annote.*=.*/ {print "   @Annote { " cont " }"; next}
/author.*=.*/ {print "   @Author { " cont " }"; next}
/chapter.*=.*/ {} # print " { " cont " }"
/date.*=.*/ {print "   @Day { " cont " }"; next}
/edition.*=.*/ {print "   @Edition { " cont " }"; next}
/howpublished.*=.*/ {print "   @HowPublished { " cont " }"; next}
/editor.*=.*/ {print "   @InAuthor { " cont " }"; next}
/booktitle.*=.*/ {print "   @InTitle { " cont " }"; next}
/institution.*=.*/ {print "   @Institution { " cont " }"; next}
/journal.*=.*/ {print "   @Journal { " cont " }"; next}
/key.*=.*/ {print "   @Keywords { " cont " }"; next}
/keywords.*=.*/ {print "   @Keywords { " cont " }"; next}
# /.*=.*/ {print "   @Label { " cont " }"; next}
/month.*=.*/ {print "   @Month { " cont " }"; next}
/note.*=.*/ {print "   @Note { " cont " }"; next}
/number.*=.*/ {print "   @Number { " cont " }"; next}
/organization.*=.*/ {print "   @Organization { " cont " }"; next}
/pages.*=.*/ {print "   @Pages { " cont " }"; next}
#/pages.*=.*/ {print "   @Page { " cont " }"; next}
# /.*=.*/ {print "   @Pinpoint { " cont " }"; next}
/location.*=.*/ {print "   # @Location { " cont " }"; next}
/doi.*=.*/ {print "   # @Doi { " cont " }"; next}
/publisher.*=.*/ {print "   @Publisher { " cont " }"; next}
/title.*=.*/ {print "   @Title { " cont " }"; next}
# /.*=.*/ {print "   @TitleNote { " cont " }"; next}
/type.*=.*/ {print "   @TRType { " cont " }"; next}
/url.*=.*/ {print "   @URL { " cont " }"; next}
/volume.*=.*/ {print "   @Volume { " cont " }"; next}
/year.*=.*/ {print "   @Year { " cont " }"; next}
/isbn.*=.*/ {print "   # @ISBN { " cont " }"; next}
/series.*=.*/ {print "   @TitleNote { " cont " }"; next}

## close the record
{if (have) print "}\n\n"; have = 0; next}
