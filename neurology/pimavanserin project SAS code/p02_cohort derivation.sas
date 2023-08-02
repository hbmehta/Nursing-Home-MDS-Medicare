/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: Tuesday, November 29, 2022     TIME: 6:41:20 PM
PROJECT: Project pimavanserin
PROJECT PATH: U:\DUA_055546\_Shared\Project pimavanserin\Project pimavanserin.egp
---------------------------------------- */

/* Unable to determine code to assign library PIMA on sasCCW */
/* Unable to determine code to assign library PIMA on sasCCW */

/* ---------------------------------- */
/* MACRO: enterpriseguide             */
/* PURPOSE: define a macro variable   */
/*   that contains the file system    */
/*   path of the WORK library on the  */
/*   server.  Note that different     */
/*   logic is needed depending on the */
/*   server type.                     */
/* ---------------------------------- */
%macro enterpriseguide;
%global sasworklocation;
%local tempdsn unique_dsn path;

%if &sysscp=OS %then %do; /* MVS Server */
	%if %sysfunc(getoption(filesystem))=MVS %then %do;
        /* By default, physical file name will be considered a classic MVS data set. */
	    /* Construct dsn that will be unique for each concurrent session under a particular account: */
		filename egtemp '&egtemp' disp=(new,delete); /* create a temporary data set */
 		%let tempdsn=%sysfunc(pathname(egtemp)); /* get dsn */
		filename egtemp clear; /* get rid of data set - we only wanted its name */
		%let unique_dsn=".EGTEMP.%substr(&tempdsn, 1, 16).PDSE"; 
		filename egtmpdir &unique_dsn
			disp=(new,delete,delete) space=(cyl,(5,5,50))
			dsorg=po dsntype=library recfm=vb
			lrecl=8000 blksize=8004 ;
		options fileext=ignore ;
	%end; 
 	%else %do; 
        /* 
		By default, physical file name will be considered an HFS 
		(hierarchical file system) file. 
		*/
		%if "%sysfunc(getoption(filetempdir))"="" %then %do;
			filename egtmpdir '/tmp';
		%end;
		%else %do;
			filename egtmpdir "%sysfunc(getoption(filetempdir))";
		%end;
	%end; 
	%let path=%sysfunc(pathname(egtmpdir));
    %let sasworklocation=%sysfunc(quote(&path));  
%end; /* MVS Server */
%else %do;
	%let sasworklocation = "%sysfunc(getoption(work))/";
%end;
%if &sysscp=VMS_AXP %then %do; /* Alpha VMS server */
	%let sasworklocation = "%sysfunc(getoption(work))";                         
%end;
%if &sysscp=CMS %then %do; 
	%let path = %sysfunc(getoption(work));                         
	%let sasworklocation = "%substr(&path, %index(&path,%str( )))";
%end;
%mend enterpriseguide;

%enterpriseguide


/* Conditionally delete set of tables or views, if they exists          */
/* If the member does not exist, then no action is performed   */
%macro _eg_conditional_dropds /parmbuff;
	
   	%local num;
   	%local stepneeded;
   	%local stepstarted;
   	%local dsname;
	%local name;

   	%let num=1;
	/* flags to determine whether a PROC SQL step is needed */
	/* or even started yet                                  */
	%let stepneeded=0;
	%let stepstarted=0;
   	%let dsname= %qscan(&syspbuff,&num,',()');
	%do %while(&dsname ne);	
		%let name = %sysfunc(left(&dsname));
		%if %qsysfunc(exist(&name)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;

			%end;
				drop table &name;
		%end;

		%if %sysfunc(exist(&name,view)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;
			%end;
				drop view &name;
		%end;
		%let num=%eval(&num+1);
      	%let dsname=%qscan(&syspbuff,&num,',()');
	%end;
	%if &stepstarted %then %do;
		quit;
	%end;
%mend _eg_conditional_dropds;


/* save the current settings of XPIXELS and YPIXELS */
/* so that they can be restored later               */
%macro _sas_pushchartsize(new_xsize, new_ysize);
	%global _savedxpixels _savedypixels;
	options nonotes;
	proc sql noprint;
	select setting into :_savedxpixels
	from sashelp.vgopt
	where optname eq "XPIXELS";
	select setting into :_savedypixels
	from sashelp.vgopt
	where optname eq "YPIXELS";
	quit;
	options notes;
	GOPTIONS XPIXELS=&new_xsize YPIXELS=&new_ysize;
%mend _sas_pushchartsize;

/* restore the previous values for XPIXELS and YPIXELS */
%macro _sas_popchartsize;
	%if %symexist(_savedxpixels) %then %do;
		GOPTIONS XPIXELS=&_savedxpixels YPIXELS=&_savedypixels;
		%symdel _savedxpixels / nowarn;
		%symdel _savedypixels / nowarn;
	%end;
%mend _sas_popchartsize;


ODS PROCTITLE;
OPTIONS DEV=ACTIVEX;
GOPTIONS XPIXELS=0 YPIXELS=0;
FILENAME EGSRX TEMP;
ODS tagsets.sasreport13(ID=EGSRX) FILE=EGSRX
    STYLE=HTMLBlue
    STYLESHEET=(URL="file:///C:/Program%20Files/SASHome/SASEnterpriseGuide/7.1/Styles/HTMLBlue.css")
    NOGTITLE
    NOGFOOTNOTE
    GPATH=&sasworklocation
    ENCODING=UTF8
    options(rolap="on")
;

/*   START OF NODE: p02_cohort derivation   */
%LET _CLIENTTASKLABEL='p02_cohort derivation';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='U:\DUA_055546\_Shared\Project pimavanserin\Project pimavanserin.egp';
%LET _CLIENTPROJECTPATHHOST='VDI-PS-L90350';
%LET _CLIENTPROJECTNAME='Project pimavanserin.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

GOPTIONS ACCESSIBLE;
options source;

/*********************************************************************
|	Cohort derivation - 02
|	Age >= 65 at cohort entry date
|
|
|*********************************************************************/

/**************************************************************************
	Get MBSF file
**************************************************************************/
data mbsf15_18 (keep= bene_id BENE_ENROLLMT_REF_YR BENE_BIRTH_DT BENE_DEATH_DT SEX_IDENT_CD RTI_RACE_CD ENTLMT_RSN_ORIG);
	set &lib.MBSF_ABCD15_R9984 &lib.MBSF_ABCD16_R9984 &lib.MBSF_ABCD17_R9984 &lib.MBSF_ABCD18_R9984;
	if BENE_DEATH_DT = . or BENE_DEATH_DT >= "01Nov2015"d;
run;

proc sql;	
create table mbsf15_18_pima as 
select b.*
from park_mocd_u as a , mbsf15_18 as b
where a.bene_id = b.bene_id
order by bene_id, bene_death_dt;
quit;
proc sql; **620,775 unique pts;
select count (bene_id) as all_clams, count (distinct bene_id) as unique_pt
from mbsf15_18_pima;
quit;
Data mbsf15_18_pima_u;
	set mbsf15_18_pima;
	by bene_id;
	if last.bene_id;
run;

/**************************************************************************
	Update cohort with at least one record in MBSF file	and get all variables
**************************************************************************/
proc sql;	**620,775 unique pts;
	create table pima.cohort_v01 as 
	select a.*, b.*
	from park_mocd_u as a, mbsf15_18_pima_u as b
	where a.bene_id = b.bene_id;
quit;



/**************************************************************************
		Identify residents with at least 1 MDS LTC assessment 
**************************************************************************/

libname opioid "&mylibs/opioid";
libname anticoag "&mylibs/anticoag";

*1. select patients in MDS from 2015-2018;
data pima.mds15_18; 
set  
&lib.mds_asmt315_R9984(where=(trgt_dt>='01Nov2015'd))
&lib.mds_asmt316_R9984 
&lib.MDS_ASMT317_R9984 
&lib.MDS_ASMT318_R9984 ;
run;
proc sort data=pima.mds15_18 nodup; by bene_id; run;

%let mdsOpt = %str(
	keep = bene_id state_cd fac_prvdr_intrnl_id a1600_entry_dt trgt_dt A0310F_ENTRY_DSCHRG_CD
	where = (bene_id ^= . & a1600_entry_dt ^= . & a1600_entry_dt <= trgt_dt));

data pima.mdsRaw15_18;
	format bene_id state_cd fac_id;
	format mdsAdmt mdsDisch date9.;
	length fac_id $12 mdsAdmt mdsDisch 4 a1600_entry_dt trgt_dt 8;
	set pima.mds15_18(&mdsOpt);
	fac_id = cats(state_cd, fac_prvdr_intrnl_id);
	mdsAdmt = a1600_entry_dt;
	mdsDisch = trgt_dt;
	drop fac_prvdr_intrnl_id a1600_entry_dt trgt_dt;
run;
proc sort data = pima.mdsRaw15_18;
	by bene_id state_cd fac_id mdsAdmt mdsDisch;
run;

proc sql;
	create table pima.mds1 as
	select distinct 
		bene_id, state_cd, fac_id, mdsAdmt,
		max(mdsDisch) as mdsDisch length = 4 format = date9.
	from pima.mdsRaw15_18
	group by bene_id, mdsAdmt
	order by bene_id, mdsAdmt, mdsDisch;
quit;

data pima.mds1(drop = lowDt highDt);	
set pima.mds1;
by bene_id;
retain lowDt highDt;
	if (first.bene_id) then do;
		lowDt = mdsAdmt;
		highDt = mdsDisch;
	end;
	else do;
		if (lowDt <= mdsAdmt <= mdsDisch <= highDt) then delete;
			else do;
				if (mdsAdmt <= highDt + 1) then	mdsAdmt = lowDt;
				else lowDt = mdsAdmt;
				if (highDt < mdsDisch) then	highDt = mdsDisch;
		end;
	end;
run;


data pima.mds1;		
	set pima.mds1;
	by bene_id mdsAdmt;
	if last.mdsAdmt;
run;

/*proc sql;*/
/*	select sum ( (mdsdisch - mdsadmt) < 0 ) */
/*	from pima.mds1;*/
/*quit;*/

proc sql;
create table pima.mds1 as
select a.* 
from pima.mds1 as a,
	(select distinct bene_id from opioid.mbsf_all) as b
where a.bene_id = b.bene_id;
quit;

proc sql;	*9,046,431;
	create table cohortDev as    
	select count(distinct bene_id) as Initial format = comma16.
	from pima.mds1;
quit;

*2. select patients in MDS from 2015-2018 in LTC;
data pima.overlap(drop = rc);		*19,061,058;
	if _N_ = 0 then set pima.mds1(keep = bene_id mdsAdmt mdsDisch);
	declare hash mds(dataset:'anticoag.mds1', multidata:'yes', hashexp: 20);
		mds.defineKey('bene_id');
		mds.defineData('mdsAdmt', 'mdsDisch');
		mds.defineDone();
	do until (eof);
		set anticoag.snf1 end = eof;
		rc = mds.find();

	do while (rc = 0);
		* Check the condition for all records in mds1 whose "bene_id" matches
		the "bene_id" of the current record of snf.The condition captures any
		possible overlap between mds and snf stays time-intervals;
		if ( (mdsAdmt <= snfDisch) &
			(snfAdmt <= mdsDisch) ) then do;
		* Captures only mds stays that are completely contained within a snf;
				if ( (snfAdmt <= mdsAdmt) & (mdsDisch <= snfDisch) ) then keepRec = 0;
				else keepRec = 1;
				output;
			end;
		rc = mds.find_next();
		end;
	end;
	stop;
run;


proc sql;
	create table pima.mds2 as
	select distinct
		a.bene_id, a.state_cd, a.fac_id,
		snfAdmt, snfDisch, keepRec, a.mdsAdmt, a.mdsDisch
	from pima.mds1 as a
	left join pima.overlap as b
	on a.bene_id = b.bene_id and
	a.mdsAdmt = b.mdsAdmt
	order by bene_id, a.mdsAdmt; 
quit;


**Creating mds3 - new data -- 25,816,642;
data pima.mds3 ( rename = (AdmtDt = mdsAdmt dischDt = mdsDisch)
			drop = mds: snf: keepRec );
	set pima.mds2(where = (keepRec ^= 0));
	by bene_id mdsAdmt;
	retain AdmtDt dischDt;
	format AdmtDt dischDt date9.;
	if first.mdsAdmt then do;
		AdmtDt = mdsAdmt;
		dischDt = mdsDisch;
	end;
	* Process only records with overlap of stays;
	if (keepRec = 1) then do;
	* SNF admission before NH admission (snfDisch within NH stay).
	* Set NH admission the day after SNF discharge;
		if (snfAdmt <= AdmtDt) then AdmtDt = snfDisch + 1;
	* Both SNF admission and discharge during the NH stay;
		else if ( (snfAdmt > AdmtDt) and (snfDisch < mdsDisch) ) then do;
	* 1st: Set NH discharge the day before SNF admission and OUTPUT;
			dischDt = snfAdmt - 1;
			stay = dischDt - AdmtDt + 1;
			output;
	* 2nd: Set NH admission the day after SNF discharge;
	* Restore NH discharge back to mdsDisch;
			AdmtDt = snfDisch + 1;
			dischDt = mdsDisch;
		end;
		else if (snfDisch >= mdsDisch) then	dischDt = snfAdmt - 1;
	end;

	if (last.mdsAdmt) then do;
		stay = dischDt - AdmtDt + 1;
		output;
	end;
run;

proc sql;
	create table cohortDev as
	select a.*, b.*
	from 
		cohortDev as a, 
		(select count(distinct bene_id) as SnfRemoved format = comma16. from pima.mds3) as b;
quit;

*3. restrain patients with >=1 days in LTC from 2015-2018, select in our cohort;
data pima.mds4;
	set pima.mds3;
	if stay >=1;
run;

proc sql;
	create table pima.cohort_v02 as
	select a.*, b.bene_id
	from pima.cohort_v01 as a, pima.mds4 as b
	where a.bene_id = b.bene_id
	order by bene_id;
run;
proc sort data=pima.cohort_v02 nodup; by _all_; run;


proc sql;
	select count(distinct bene_id)
	from pima.cohort_v02;
quit;



options nosource;

GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;

;*';*";*/;quit;run;
ODS _ALL_ CLOSE;
