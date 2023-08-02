/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: Tuesday, November 29, 2022     TIME: 6:43:29 PM
PROJECT: Project pimavanserin
PROJECT PATH: U:\DUA_055546\_Shared\Project pimavanserin\Project pimavanserin.egp
---------------------------------------- */

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

/*   START OF NODE: p17_kmplot9   */
%LET _CLIENTTASKLABEL='p17_kmplot9';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='U:\DUA_055546\_Shared\Project pimavanserin\Project pimavanserin.egp';
%LET _CLIENTPROJECTPATHHOST='VDI-PS-L90350';
%LET _CLIENTPROJECTNAME='Project pimavanserin.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

GOPTIONS ACCESSIBLE;
options source;

%macro kmplot9(data=, strata=_mvar_, where=, time=, censor=,  showci=T,
	       pictname=&data..&time..&censor..&strata..&outplot,
               pictdirec=,
	       vlabel=, vlabelstyle=v, 
	       timelist=, pwhich=inc, extend=f,
	       axordv=0.00 to 1.00 by .10,   axordt=,
	       tlabel=Time,
               plot=2,  outplot=PS,
               plotdata=&data..&time..&censor..txt,
	       strname=Stratum,
	       font=swiss,
	       href=, vref=,
	       header1=, header2=, header3=,   hsize1=2, hsize2=1.7, hsize3=1.5,
               atrisktab=T,  textlength=20, fontmult=1,
               widelabel=F,
	       nolegend=F, legloc=center bottom outside ,
               legframe=F, legacross=1,
	       leglabel=Stratum, leglab1=, leglab2=,
	       leglab3=, leglab4=, leglab5=, leglab6=, leglab7=, 
               color1=black, color2=red, color3=tan, color4=lib, color5=violet,
               color6=gold, color7=pink,
               landscape=F,
               linetype1=1, linetype2=1, linetype3=1, linetype4=1, linetype5=1,
               linetype6=1, linetype7=1,
               linewidth=6,
               outdat=, notes=nonotes);
   
   options &notes nosyntaxcheck;
   
   
%local i j nstrat _fdl _nt _t1 _t2 _t3   _derr_ _terr_ _cerr_ _ederr_  _ntl _bterr_ 
   _xoff_ _yoff_
fm7 fm14 fm15 fm2
   ;
   
  /* preserving existing options */
%let _fdl = %sysfunc(getoption(formdlim));
%let _nt = %sysfunc(getoption(notes));
   
   options &notes formdlim='[';
   
   
   /* fixing macro variables */
%let notes=%upcase(&notes);
%let showci=%upcase(&showci);
%let nolegend=%upcase(&nolegend);
%let legframe=%upcase(&legframe);
%let legloc=%upcase(&legloc);
%let pwhich=%upcase(&pwhich);
%let extend=%upcase(&extend);
%if %length(&strata) eq 0 %then %do;  %let strata=_mvar_;  %end;
%let strata = %upcase(&strata);
%let outplot=%upcase(&outplot);
%let atrisktab=%upcase(&atrisktab);
%let landscape=%upcase(&landscape);
%let widelabel=%upcase(&widelabel);
%let vlabelstyle=%upcase(&vlabelstyle);
%if "&atrisktab" ne "T" %then %let widelabel=F;
%if "&outplot" eq "POSTSCRIPT" %then %do;  %let outplot = PS ;  %end;
%if "&strata" eq "_MVAR_" %then %do;  %let nolegend=T;  %end;
   
%let _ntl = %numargs(&timelist);
%if &_ntl ne 0 %then %do;
   %do i=1 %to &_ntl;
      %let _tl&i=%scan(&timelist, &i, %str( ));
      %end;
%end;

/**********************
 new macro vbls to get font multiplication
************************/
data _null_;
   fm=&fontmult;
   fm7=.7*fm;
   fm14=1.4*fm;
   fm15=1.5*fm;
   fm2=2*fm;
   call symput('fm7', trim(left(fm7)));
   call symput('fm14', trim(left(fm14)));
   call symput('fm15', trim(left(fm15)));
   call symput('fm2', trim(left(fm2)));
   run;
   
   
  /*******************************
   checking for required parameters
   *******************************/
%let _derr_ = 0;  %let _terr_ = 0;  %let _cerr_ = 0;  %let _ederr_ = 0;
%let _bterr_ = 0;
%if "&data" eq "" %then %do;  %let _derr_ = 1;  %end;
%else %do;
   %if ^%sysfunc(exist(&data)) %then %do;  %let _ederr_ = 1;  %end;
%end;
%if "&time" eq "" %then %do;  %let _terr_ = 1;  %end;
%if "&censor" eq "" %then %do;  %let _cerr_ = 1;  %end;
%if "&atrisktab" eq "T" and &_ntl eq 0 %then %do;  %let _bterr_ = 1;  %end;
   
data _null_;  derr=&_derr_;  terr=&_terr_;  cerr=&_cerr_;  ederr=&_ederr_;
   if max(derr, terr, cerr, ederr) eq 1 then do;
      if derr eq 1 then do;
	 put 'ERROR in MACRO call:  No data set named';
	 end;
      if ederr eq 1 then do;
	 put "ERROR in MACRO call:  Data set named (&data ) does not exist";
	 put '  Check your spelling.';
	 end;
      if terr eq 1 then do;
	 put 'ERROR in MACRO call:  No time variable given';
	 end;
      if cerr eq 1 then do;
	 put 'ERROR in MACRO call:  No censoring variable given';
	 end;
      put 'The KMPLOT9 macro will stop.';
      file print;
      if derr eq 1 then do;
	 put 'ERROR in MACRO call:  No data set named';
	 end;
      if ederr eq 1 then do;
	 put "ERROR in MACRO call:  Data set named (&data ) does not exist";
	 put '  Check your spelling.';
	 end;
      if terr eq 1 then do;
	 put 'ERROR in MACRO call:  No time variable given.';
	 end;
      if cerr eq 1 then do;
	 put 'ERROR in MACRO call:  No censoring variable given';
	 end;
      put 'The KMPLOT9 macro will stop.';
      end;
   run;
   
%if &_derr_ eq 1 or &_ederr_ eq 1 or &_terr_ eq 1 or &_cerr_ eq 1 %then %goto out;
   
   %if &_bterr_ eq 1 %then %do;  %let atrisktab = F;
      data _null_;
      put 'WARNING:  Problem in MACRO call:  ATRISKTAB=T, but there is no TIMELIST';
      put '  The macro will continue, setting ATRISKTAB=F';
      file print;
      put 'WARNING:  Problem in MACRO call:  ATRISKTAB=T, but there is no TIMELIST';
      put '  The macro will continue, setting ATRISKTAB=F';
      run;
      %end;
   
   title1;
   
   
/*************************
location of legend
*************************/
%if %length(&legloc) eq 0 and &nolegend eq F %then %do;
   %if &pwhich eq INC %then %let legloc=BOTTOM RIGHT INSIDE;
   %if &pwhich eq SURV %then %let legloc=BOTTOM LEFT INSIDE;
%end;
%let _xoff_=0;  %let _yoff_=0;
 /* make offsets only if there is an inside legend */
%if &nolegend eq F %then %do;
   %if %scan(&legloc, 1, %str( )) eq INSIDE or
      %scan(&legloc, 2, %str( )) eq INSIDE or
      %scan(&legloc, 3, %str( )) eq INSIDE %then %do;
	 %if %scan(&legloc, 1, %str( )) eq LEFT or
	    %scan(&legloc, 2, %str( )) eq LEFT or
	    %scan(&legloc, 3, %str( )) eq LEFT %then  %let _xoff_=5;
	 %if %scan(&legloc, 1, %str( )) eq RIGHT or
	    %scan(&legloc, 2, %str( )) eq RIGHT or
	    %scan(&legloc, 3, %str( )) eq RIGHT %then  %let _xoff_=-5;
	 %if %scan(&legloc, 1, %str( )) eq BOTTOM or
	    %scan(&legloc, 2, %str( )) eq BOTTOM or
	    %scan(&legloc, 3, %str( )) eq BOTTOM %then  %let _yoff_=5;
	 %if %scan(&legloc, 1, %str( )) eq TOP or
	    %scan(&legloc, 2, %str( )) eq TOP or
	    %scan(&legloc, 3, %str( )) eq TOP %then  %let _yoff_=-5;
	 %end;
%end;
   
   
/*******************
titles
*******************/   
%macro hd;
%if %length(&header1) ne 0 %then %do;
   title1 j=c f=&font.b c=black h=&hsize1  "&header1";
%end;
%if %length(&header2) ne 0 %then %do;
   title2 j=c f=&font.b c=black h=&hsize2  "&header2";
%end;
%if %length(&header3) ne 0 %then %do;
   title3 j=c f=&font.b c=black h=&hsize3  "&header3";
%end;
%mend;


 /**********************************
more parameters that need filling in
 ***********************************/
%if %length(&vlabel) eq 0 %then %do;
   %if &pwhich eq SURV %then %do;
      %let vlabel=Fraction not Failed ;
      %end;
   %if &pwhich eq INC %then %do;
      %let vlabel=Cumulative Incidence ;
      %end;
%end;

%if %length(&axordv) ne 0 %then %do;
   %let vmin=%scan(&axordv, 1, %str( ));
   %let vmax=%scan(&axordv, 3, %str( ));
%end;

 /******************
 data for analysis
********************/
data _aabbcc_;  set &data;
%if %length(&where) ne 0 %then %do;  where &where;  %end;
   _mvar_=1;
   if &strata ne . ;
   run;
proc sort data=_aabbcc_;  by &strata;  run;
   
   /*************************
 fixing axordv if missing 
**************************/
%if %length(&axordv) eq 0 %then %do;
   %let axordv = 0 to 1 by .1 ;
%end;
   
   /***********************
 fixing axordt, if not specified 
************************/
%if %length(&axordt) eq 0 %then %do;
   proc means noprint data=_aabbcc_;  var &time;
   output  out=tminmax  min=tmin  max=tmax;
   run;
   data tminmax;  set tminmax;
   tinc=tmax/10;
   call symput('tmax', trim(left(tmax)));  call symput('tinc',trim(left(tinc)));
   run;
   %let axordt = 0 to &tmax by &tinc ;
%end;
%else %do;
   %let tmax=%scan(&axordt, 3, %str( ));
   %let tinc=%scan(&axordt, 5, %str( ));
%end;
   
   
   /*************************
 the proc lifetest 
********************/
   ods listing close;
   ods output
      productlimitestimates = plest
      censoredsummary = censum
      %if "&strata" ne "_MVAR_" %then %do;
	 homtests = homtests
	    %end;
   ;
   proc lifetest data=_aabbcc_ method=km outsurv=kamecur
  /*
   %if %length(&timelist) eq 0 %then %do;  notable   %end;
   */
      %if %length(&timelist) ne 0 %then %do;
	 timelist=&timelist
	    %end;
   ;
   
   time &time * &censor (0) ;
   strata &strata;
   %if "&strata" ne "_MVAR_" %then %do;
      test &strata;
      %end;
   run;

data kamecur1;  set kamecur;  run;

data kamecur;  set kamecur;  by &strata &time;  
retain oldsdf_lcl oldsdf_ucl oldsurv;
if first.&strata then do;  oldsdf_lcl=.;  oldsdf_ucl=.;  oldsurv=.;  end;
%if "&extend" eq "T" %then %do;
if survival eq . then survival=oldsurv;
if sdf_lcl eq . then sdf_lcl=oldsdf_lcl;
if sdf_ucl eq . then sdf_ucl=oldsdf_ucl;
%end;
if first.&time then output;
oldsurv=survival;  oldsdf_lcl=sdf_lcl;  oldsdf_ucl=sdf_ucl;
run;
   
data censum;  set censum;  pctfail=100-pctcens;
   length _strat_  _strtm_ $8 ;
   if control_var eq '-' then do;  _strtm_='TOTAL';
      _strat_=' ';
      end;
   else do;  _strtm_=stratum;  end;
%if "&strata" ne "" %then %do;
   if control_var eq '-' then do;  _strat_=' ';
      label _strat_=&strata;
      end;
%end;
   label _strtm_='Stratum'
      pctfail='Percent Failed'
      ;
   ;
   run;
   
   /**********************************************
 information for graphing
    Derive number at risk at select time points 
*************************************************/
%if %length(&timelist) ne 0 %then %do;
   %do i=1 %to &_ntl;
      data nrisk;  set _aabbcc_;  by &strata;
      retain strnum 0;
      if first.&strata then strnum=strnum+1;
      run;
      data nrisk;  set nrisk;  by &strata;  where &time ge &&_tl&i;  run;
      proc means noprint data=nrisk;  var &time;
      output  out=nrisk1  n=atrisk;  by &strata strnum;
      run;
      data nrisk1;  set nrisk1;
      call symput('atrisk'||compress(strnum||'_'||&i), trim(left(atrisk)));
      %end;
%end;  /* end of length(timelist) ne 0 */
   
   /**********************************************************
 create annotate dataset using the macro variables for 
    number of people at risk 
*************************************************************/ 
%macro getantt;
   data anno;
   length function style $8. text $&textlength.. color $8.;
   nstrat=&nstrat;
   style="&font.b"; 
   ysys='3';
   %if "&vlabelstyle" ne "V" %then %do;  xsys='3';  x=0;  %end;
   %else %do;  xsys='3';  x=.1;  %end;
   y=3*(nstrat+3); position='6';
   %if "&outplot" eq "PS" or "&outplot" eq "CGM"  or "&outplot" eq "PDF"
      %then %do;  size=&fm14;  %end;      
   %else %do;  size=&fm7;  %end;
   function='label'; text='Number at Risk';
   color='black'; output;
   %do i=1 %to &nstrat;
      style="&font"; 
      x=0;
      y=3*(3+nstrat- &i); color="&&color&i"; 
      text=left(trim("&&leglab&i"));
      output;
      %end;
   run;
   
   data nanno;
   length function style $8. text $20. color $8.;
   retain style "&font"; 
   nstrat=&nstrat;
   xsys='3';
   %do i=1 %to &nstrat;
      y=3*(3+nstrat - &i);
      %do j= 1 %to &_ntl  ;
	 position='5';
	 xsys='2'; ysys='3';
	 function='label';
	 x=&&_tl&j;
	 color="&&color&i";
	 text=compress("&&atrisk&i._&j");
         if substr(text, 2, 1) eq 'a' then text='0';
         %if "&outplot" eq "PS" or "&outplot" eq "CGM" or "&outplot" eq "PDF" %then %do;
	    size= &fm14;
	    %end;
         %else %do;  size= &fm7;  %end;
         output;
	 %end;
      %end;
   run;
   
   data annods;
   set anno nanno;
   run;
%mend getantt; 
   
/***********************
 get number of strata
***********************/
proc means noprint data=kamecur;  var stratum;
   output  out=varval  max=nstrat;
   run;
data varval;  set varval;
   call symput ('nstrat', nstrat);
   run;
   
   
proc sort data=kamecur;  by &strata &time;  run;
   data kamecur;  set kamecur;  by &strata &time;
   if &time eq 0   or last.&strata  or last.&time ;  /* surv after all failures */
   nstrat=&nstrat;
   inc=1-survival;  ilcl=1-sdf_ucl;  iucl=1-sdf_lcl;
   if survival ne 0 then ls=log(survival);
   run;
   %if &notes eq NOTES %then %do;
      ods listing;
      proc print data=kamecur;  run;
      ods listing close;
      %end;
   run;
   
/***************
plot=2
***************/   
%if &plot eq 2 %then %do;
   /* stuff for proc gplot */
   filename gfile "&pictdirec&pictname";
   
   goptions   reset=all 
%if "&outplot" ne "PDF" %then %do;  gaccess=sasgaedt    %end;
      %if "&outplot" eq "PS" %then %do;  device=psepsf  %end;
   %else %if "&outplot" eq "HTML" %then %do;  device=html  %end;
   %else %if "&outplot" eq "CGM" %then %do;  device=cgm  %end;
   %else %if "&outplot" eq "PDF" %then %do;  device=pdfc  %end;
   %else %if "&outplot" eq "JPEG" %then %do;  device=jpeg  %end;
   %if &landscape eq T %then %do;  rotate=landscape  %end;
   gsfmode=replace  gsfname=gfile  gsflen=80 gunit=pct;
   
%macro symbs;
   symbol1 interpol=steplj h=4 l=&linetype1 v=none c=&color1 w=&linewidth ;
   symbol2 interpol=steplj h=4 l=&linetype2 v=none c=&color2 w=&linewidth ;
   symbol3 interpol=steplj h=4 l=&linetype3 v=none c=&color3 w=&linewidth ;
   symbol4 interpol=stepLJ l=&linetype4 h=4 v=none  c=&color4 w=&linewidth ;
   symbol5 interpol=stepLJ l=&linetype5 h=4 v=none  c=&color5 w=&linewidth ;
   symbol6 interpol=stepLJ l=&linetype6 h=4 v=none  c=&color6 w=&linewidth ;
   symbol7 interpol=stepLJ l=&linetype7 h=4 v=none  c=&color7 w=&linewidth ;
   symbol8 interpol=stepLJ l=35 h=4 v=none c=&color1 w=&linewidth;
%mend;
   
   ods listing;
   
%if &atrisktab eq T %then %do;
   %getantt;
%end;
   
 /*********************************
  make legend if nolegend ne T 
************************************/
   %if &nolegend ne T %then %do;
      legend1 label=none 
	 shape=symbol(5,.8)
	 across=&legacross 
	 offset=(&_xoff_ pct, &_yoff_ pct) 
	 %if "&legframe" eq "T" %then %do;  frame  %end;
      position=( &legloc)
	 mode=share
	 value=(f=&font h=&fm15 justify=right
		%do i=1 %to &nstrat;  tick = &i "&&leglab&i"  %end; )
	 ;
      %end;
   /*************************
axes and origin
*********************/
%if &vlabelstyle eq V %then %do;
   axis1 label=(h=&fm2 f=&font.b a=90 "&vlabel" ) 
%end;
%else %do;  /* vlabelstyle not vertical */
  %let _nvl_ = %numargs(&vlabel);
  %if &_nvl_ eq 1 %then %do;
    axis1  label=(h=&fm2 f=&font.b  "&vlabel" a=90)  
  %end;
  %else %do;
    %do i=1 %to &_nvl_;  %let _vl&i = %scan(&vlabel, &i, %str( ));  %end;
    axis1  label=(h=&fm2 f=&font.b
       %do i=1 %to &_nvl_;  "&&_vl&i" j=l  %end;
       a=90)
  %end;
%end;
      value=(f=&font h=&fm2 c=black)
      minor=none
      order=&axordv ;
   
   axis2 label=(h=&fm2 f=&font.b "&tlabel")
      value=(f=&font h=&fm2 c=black)
      order= &axordt
      minor=none
      offset=(,10 pct)

      %if "&atrisktab" ne "T" %then %do;
         %if &vlabelstyle eq V %then %do;
	    origin=(20 percent, 21 percent)
         %end;
         %else %do;  /* horizontal axis labels */
            origin=(30 percent, 21 percent)
         %end;
            %end;  /* end of atrisktab ne t */
   %else %if "&atrisktab" eq "T" %then %do;
      %if "&widelabel" ne "T" %then %do;
         %if &vlabelstyle eq V %then %do;
	    origin=(20 percent, %eval(3*(&nstrat+6)) percent)
         %end;
         %else %do;  /* horizontal axis labels */
            origin=(30 percent, %eval(3*(&nstrat+6)) percent)
         %end;
            %end;  /* end of widelabel ne T */
      %else %do;  /* widelabel eq T */
         %if &vlabelstyle eq V %then %do;
	    origin=(40 percent, %eval(3*(&nstrat+6)) percent)
         %end;
         %else %do;  /* horizontal label for vertical axis */
            origin=(40 percent, %eval(3*(&nstrat+6)) percent)
         %end;
            %end;  /* end of widelabel eq t */
      %end;  /* end of atrisktab eq t */
   
      value=(f=&font h=&fm2 c=black)
      minor=none
      order=&axordt ;
   
   
proc sort data=kamecur;  by &time stratum ;  run;
   
/*****************************
plot=2, survival plots
************************/
%if &pwhich eq SURV %then %do;
   %if &nstrat eq 1 %then %do;
proc sort data=kamecur;  by &time;  run;
      proc gplot data=kamecur;
      %symbs;
      plot survival* &time = 1
         %if &showci eq T %then %do;
         sdf_lcl* &time = 8
         sdf_ucl* &time = 8
         %end;
	 /      haxis=axis2  vaxis=axis1
           %if &showci eq T %then %do;  overlay  %end;
	 %if "&atrisktab" eq "T" %then %do;  annotate=annods 
             %if "&nolegend" eq "T" %then %do;  nolegend  %end;
            %end;
      %if "&nolegend" eq "F" %then %do;  legend=legend1   %end;
      %if "&href" ne "" %then %do;  href=&href lhref=34  %end;
      %if "&vref" ne "" %then %do;  vref=&vref lvref=34  %end;
      ;
      %hd;
      run;
      %end;
   %else %do;
      proc gplot data=kamecur;
      %symbs;
      plot survival*&time=stratum  
	 / haxis= axis2  vaxis=axis1   
	 %if "&atrisktab" eq "T" %then %do;  annotate=annods 
             %if "&nolegend" eq "T" %then %do;  nolegend  %end;
            %end;
      %if "&nolegend" eq "F" %then %do;  legend=legend1   %end;
      %if "&href" ne "" %then %do;  href=&href lhref=34  %end;
      %if "&vref" ne "" %then %do;  vref=&vref lvref=34  %end;
      ;  ;
      %hd;
      run;
      %end;
%end;
   
/*********************************
plot=2, incidence plots
****************************/
%else %if &pwhich eq INC %then %do;
   %if &nstrat eq 1 %then %do;
      proc gplot data=kamecur;
      %symbs;
      plot inc * &time = 1
      %if &showci eq T %then %do;
         iucl * &time = 8
         ilcl * &time = 8
      %end;
	 /      haxis=axis2  vaxis=axis1
          %if &showci eq T %then %do;  overlay  %end;
	 %if "&atrisktab" eq "T" %then %do;  annotate=annods 
             %if "&nolegend" eq "T" %then %do;  nolegend  %end;
            %end;
      %if "&nolegend" eq "F" %then %do;  legend=legend1   %end;
      %if "&href" ne "" %then %do;  href=&href lhref=34  %end;
      %if "&vref" ne "" %then %do;  vref=&vref lvref=34  %end;
      ;
      %hd;
      run;
      %end;
   %else %do;
      proc gplot data=kamecur;
      %symbs;
      plot inc*&time=stratum 
	 / haxis= axis2  vaxis=axis1 
	 %if "&atrisktab" eq "T" %then %do;  annotate=annods 
             %if "&nolegend" eq "T" %then %do;  nolegend  %end;
            %end;
      %if "&nolegend" eq "F" %then %do;  legend=legend1   %end;
      %if "&href" ne "" %then %do;  href=&href lhref=34  %end;
      %if "&vref" ne "" %then %do;  vref=&vref lvref=34  %end;
      ;
      %hd;
      run;
      %end;
   
%end;
%end;  /* end of plot eq 2 */

/****************************
plot=4:  making points for pc graphics
****************************/
%if &plot eq 4 %then %do;
data kamecur;  set kamecur;
   file "&plotdata";
   bar='|';
   put &strata bar &time bar survival bar sdf_lcl bar sdf_ucl bar
      inc bar ilcl bar iucl ;
   run;
%end;
   
 ods listing;
 options notes;

/********************
plot=1
*********************/
%if &plot eq 1 %then %do;
/*********************************
plot=1, survival plots
****************************/
%if &pwhich eq SURV %then %do;
   %if &nstrat eq 1 %then %do;
      proc plot data=kamecur;
      plot survival* &time = 'S'
         sdf_lcl* &time = '-'
         sdf_ucl* &time = '-'
	 /    overlay  haxis=&axordt  vaxis=&axordv
      %if "&href" ne "" %then %do;  href=&href   %end;
      %if "&vref" ne "" %then %do;  vref=&vref   %end;
      ;
      run;
      %end;
   %else %do;
      proc plot data=kamecur;
      plot survival*&time=stratum  
	 / haxis= &axordt  vaxis=&axordv
      %if "&href" ne "" %then %do;  href=&href   %end;
      %if "&vref" ne "" %then %do;  vref=&vref   %end;
      ;  ;
      run;
      %end;
%end;

/*****************************
plot=1, incidence plots
***************************/   
%else %if &pwhich eq INC %then %do;
   %if &nstrat eq 1 %then %do;
      proc plot data=kamecur;
      plot inc * &time = 'I'
         iucl * &time = '-'
         ilcl * &time = '-'
	 /    overlay  haxis=&axordt  vaxis=&axordv
      %if "&href" ne "" %then %do;  href=&href   %end;
      %if "&vref" ne "" %then %do;  vref=&vref   %end;
      ;
      run;
      %end;
   %else %do;
      proc plot data=kamecur;
      plot inc*&time=stratum 
	 / haxis= &axordt  vaxis=&axordv
      %if "&href" ne "" %then %do;  href=&href   %end;
      %if "&vref" ne "" %then %do;  vref=&vref   %end;
      ;
      run;
      %end;
   
%end;
%end;
	    
   title5 "makes graph &pictname";
   %if %length(&where) ne 0 %then %do;
     title6 "where &where";
   %end;
	    
	    %if "&timelist" ne "" %then %do;
	       proc sort data=plest;  by stratum &strata &time;  run;
/*
	       proc print label noobs data=kamecur;  var &time failed survival survlcl survucl inc inclcl incucl left ;
	       %if "&strata" ne "_MVAR_" %then %do;
		  by stratum &strata;
		  %end;
*/
	       %end;
	    
proc print label noobs data=censum;  var _strtm_ 
%if "&strata" ne "_MVAR_" %then %do;  _strat_   %end;
   total failed pctfail censored pctcens;  run;
   %if "&strata" ne "_MVAR_" %then %do;
proc print label noobs data=homtests;  run;
%end;

%if %length(&outdat) ne 0 %then %do;
  data _null_;  set homtests;
  if upcase(test) eq 'LOG-RANK';
  call symput ('plogrank', trim(left(probchisq)));
  run;
  data &outdat;  set censum;
  plogrank=&plogrank;  format plogrank pvalue6.4;
  run;
%end;

options &notes;
proc datasets nolist;
  delete  censum  kamecur varval _aabbcc_ tminmax nrisk maxtime ;  run;
%if "&strata" ne "_MVAR_" %then %do;
   proc datasets nolist;  delete homtests;  run;
%end;
%if "&timelist" ne "" %then %do;
   proc datasets nolist;   delete plest;  run;
%end;
%if &atrisktab eq "T" %then %do;
   proc datasets nolist;  delete anno nanno annods;  run;
%end;
   
%out:
   ods listing;
   options notes  formdlim="&_fdl"  syntaxcheck;
   title1;
%mend;
   


%*                                                                            ;
%* This macro was developed by Carrie Wager,Programmer,Channing Laboratory 1990;
%* Modified AMcD 1993, e hertzmark 1994 and L Chen 1996;
%*                                                                            ;

%macro numargs(arg, delimit);
   %if %quote(&arg)= %then %do;
        0
   %end;
   %else %do;
     %let n=1;
     %do %until (%qscan(%quote(&arg), %eval(&n), %str( ))=%str()); 
        %let n=%eval(&n+1);
        %end;
	%eval(&n-1)
   %end;
   %mend numargs;


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
