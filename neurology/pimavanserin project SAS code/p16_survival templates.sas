/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: Tuesday, November 29, 2022     TIME: 6:43:23 PM
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

/*   START OF NODE: p16_survival templates   */
%LET _CLIENTTASKLABEL='p16_survival templates';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='U:\DUA_055546\_Shared\Project pimavanserin\Project pimavanserin.egp';
%LET _CLIENTPROJECTPATHHOST='VDI-PS-L90350';
%LET _CLIENTPROJECTNAME='Project pimavanserin.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

GOPTIONS ACCESSIBLE;
options source;

/****************************************************************/
/*          S A S   S A M P L E   L I B R A R Y                 */
/*                                                              */
/*    NAME: TEMPLFT                                             */
/*   TITLE: PROC LIFETEST Template                              */
/* PRODUCT: STAT                                                */
/*  SYSTEM: ALL                                                 */
/*    KEYS: graphics, ods, survival analysis, Kaplan-Meier      */
/*   PROCS:                                                     */
/*    DATA:                                                     */
/*                                                              */
/* SUPPORT: saswfk                UPDATE: July 25, 2013         */
/*     REF: ods graphics                                        */
/*    MISC:                                                     */
/*   NOTES: This sample provides templates for the PROC         */
/*          LIFETEST survival plot that are modular and         */
/*          easier to modify than the default templates.        */
/****************************************************************/

%macro ProvideSurvivalMacros;

   %global atriskopts bandopts censored censorstr classopts
           graphopts groups insetopts legendopts ntitles stepopts tiplabel
           tips titletext0 titletext1 titletext2 xoptions yoptions;

   %let TitleText0 = METHOD " Survival Estimate";
   %let TitleText1 = &titletext0 " for " STRATUMID;
   %let TitleText2 = &titletext0 "s";         /* plural: Survival Estimates */
   %let nTitles    = 2;

   %let yOptions   = label="Survival Probability" shortlabel="Survival"
                     linearopts=(viewmin=0 viewmax=1
                                 tickvaluelist=(0 .2 .4 .6 .8 1.0));

   %let xOptions   = shortlabel=XNAME offsetmin=.05
                     linearopts=(viewmax=MAXTIME tickvaluelist=XTICKVALS
                                 tickvaluefitpolicy=XTICKVALFITPOL);

   %let Tips       = rolename=(_tip1= ATRISK _tip2=EVENT)
                     tiplabel=(_tip1="Number at Risk" _tip2="Observed Events")
                     tip=(x y _tip1 _tip2);
   %let TipLabel   = tiplabel=(y="Survival Probability");
   %let StepOpts   = ;

   %let Groups     = group=STRATUM index=STRATUMNUM;

   %let BandOpts   = &groups modelname="Survival";

   %let InsetOpts  = autoalign=(TOPRIGHT BOTTOMLEFT TOP BOTTOM)
                     border=true BackgroundColor=GraphWalls:Color Opaque=true;
   %let LegendOpts = title=GROUPNAME location=outside;

   %let AtRiskOpts = display=(label) valueattrs=(size=7pt);
   %let ClassOpts  = class=CLASSATRISK colorgroup=CLASSATRISK;

   %let Censored   = markerattrs=(symbol=plus);
   %let CensorStr  = "+ Censored";

   %let GraphOpts  = ;

   %macro StmtsBeginGraph; %mend;
   %macro StmtsTop;        %mend;
   %macro StmtsBottom;     %mend;

   %macro CompileSurvivalTemplates;
      %local outside;
      proc template;
         %do outside = 0 %to 1;
            define statgraph
               Stat.Lifetest.Graphics.ProductLimitSurvival%scan(2,2-&outside);
               dynamic NStrata xName plotAtRisk
                  %if %nrbquote(&censored) ne %then plotCensored;
                  plotCL plotHW plotEP labelCL labelHW labelEP maxTime xtickVals
                  xtickValFitPol rowWeights method StratumID classAtRisk 
                  plotTest GroupName Transparency SecondTitle TestName pValue
                  _byline_ _bytitle_ _byfootnote_;
               BeginGraph %if %nrbquote(&graphopts) ne %then / &graphopts;;

               if (NSTRATA=1)
                  %if &ntitles %then %do;
                     if (EXISTS(STRATUMID)) entrytitle &titletext1;
                     else                   entrytitle &titletext0;
                     endif;
                  %end;

                  %if &ntitles gt 1 %then %do;
                     %if not &outside %then if (PLOTATRISK=1);
                        entrytitle "With Number of Subjects at Risk" /
                                   textattrs=GRAPHVALUETEXT;
                     %if not &outside %then %do; endif; %end;
                  %end;

                  %StmtsBeginGraph
                  %AtRiskLatticeStart
                  layout overlay / xaxisopts=(&xoptions) yaxisopts=(&yoptions);
                     %StmtsTop
                     %SingleStratum
                     %StmtsBottom
                  endlayout;
                  %AtRiskLatticeEnd

               else
                  %if &ntitles %then %do; entrytitle &titletext2; %end;
                  %if &ntitles gt 1 %then %do;
                     if (EXISTS(SECONDTITLE))
                        entrytitle SECONDTITLE / textattrs=GRAPHVALUETEXT;
                     endif;
                  %end;

                  %StmtsBeginGraph
                  %AtRiskLatticeStart
                  layout overlay / xaxisopts=(&xoptions) yaxisopts=(&yoptions);
                     %StmtsTop
                     %MultipleStrata
                     %StmtsBottom
                  endlayout;
                  %AtRiskLatticeEnd(class)

               endif;

               if (_BYTITLE_) entrytitle _BYLINE_ / textattrs=GRAPHVALUETEXT;
               else if (_BYFOOTNOTE_) entryfootnote halign=left _BYLINE_; endif;
               endif;
               EndGraph;
            end;
         %end;
      run;
   %mend;

   %macro pValue;
      if (PVALUE < .0001)
         entry TESTNAME " p " eval (PUT(PVALUE, PVALUE6.4));
      else
         entry TESTNAME " p=" eval (PUT(PVALUE, PVALUE6.4));
      endif;
   %mend;

   %macro SingleStratum;
      if (PLOTHW=1 AND PLOTEP=0)
         bandplot LimitUpper=HW_UCL LimitLower=HW_LCL x=TIME /
            modelname="Survival" fillattrs=GRAPHCONFIDENCE
            name="HW" legendlabel=LABELHW;
      endif;
      if (PLOTHW=0 AND PLOTEP=1)
         bandplot LimitUpper=EP_UCL LimitLower=EP_LCL x=TIME /
            modelname="Survival" fillattrs=GRAPHCONFIDENCE
            name="EP" legendlabel=LABELEP;
      endif;
      if (PLOTHW=1 AND PLOTEP=1)
         bandplot LimitUpper=HW_UCL LimitLower=HW_LCL x=TIME /
            modelname="Survival" fillattrs=GRAPHDATA1 datatransparency=.55
            name="HW" legendlabel=LABELHW;
         bandplot LimitUpper=EP_UCL LimitLower=EP_LCL x=TIME /
            modelname="Survival" fillattrs=GRAPHDATA2
            datatransparency=.55 name="EP" legendlabel=LABELEP;
      endif;
      if (PLOTCL=1)
         if (PLOTHW=1 OR PLOTEP=1)
            bandplot LimitUpper=SDF_UCL LimitLower=SDF_LCL x=TIME /
               modelname="Survival" display=(outline)
               outlineattrs=GRAPHPREDICTIONLIMITS name="CL" legendlabel=LABELCL;
         else
            bandplot LimitUpper=SDF_UCL LimitLower=SDF_LCL x=TIME /
               modelname="Survival" fillattrs=GRAPHCONFIDENCE name="CL"
               legendlabel=LABELCL;
         endif;
      endif;

      stepplot y=SURVIVAL x=TIME / name="Survival" &tips legendlabel="Survival"
               &stepopts;

      if (PLOTCENSORED=1)
         scatterplot y=CENSORED x=TIME / &censored &tiplabel
            name="Censored" legendlabel="Censored";
      endif;

      if (PLOTCL=1 OR PLOTHW=1 OR PLOTEP=1)
         discretelegend "Censored" "CL" "HW" "EP" / location=outside
            halign=center;
      else
         if (PLOTCENSORED=1)
            discretelegend "Censored" / location=inside
                                        autoalign=(topright bottomleft);
         endif;
      endif;
      %if not &outside %then %do;
         if (PLOTATRISK=1)
            innermargin / align=bottom;
               axistable x=TATRISK value=ATRISK / &atriskopts;
            endinnermargin;
         endif;
      %end;
   %mend;

   %macro MultipleStrata;
     if (PLOTHW=1)
         bandplot LimitUpper=HW_UCL LimitLower=HW_LCL x=TIME / &bandopts
                  datatransparency=Transparency;
      endif;
      if (PLOTEP=1)
         bandplot LimitUpper=EP_UCL LimitLower=EP_LCL x=TIME / &bandopts
                  datatransparency=Transparency;
      endif;
      if (PLOTCL=1)
         if (PLOTHW=1 OR PLOTEP=1)
            bandplot LimitUpper=SDF_UCL LimitLower=SDF_LCL x=TIME / &bandopts
                     display=(outline) outlineattrs=(pattern=ShortDash);
         else
            bandplot LimitUpper=SDF_UCL LimitLower=SDF_LCL x=TIME / &bandopts
                     datatransparency=Transparency;
         endif;
      endif;

      stepplot y=SURVIVAL x=TIME / &groups name="Survival" &tips &stepopts;

      if (PLOTCENSORED=1)
         scatterplot y=CENSORED x=TIME / &groups &tiplabel &censored;
      endif;

      %if not &outside %then %do;
         if (PLOTATRISK=1)
            innermargin / align=bottom;
               axistable x=TATRISK value=ATRISK / &atriskopts &classopts;
            endinnermargin;
         endif;
      %end;

      %if %nrbquote(&legendopts) ne %then %do;
         DiscreteLegend "Survival" / &legendopts;
      %end;

      %if %nrbquote(&insetopts) ne %then %do;
         if (PLOTCENSORED=1)
            if (PLOTTEST=1)
               layout gridded / rows=2 &insetopts;
                  entry &censorstr;
                  %pValue
               endlayout;
            else
               layout gridded / rows=1 &insetopts;
                  entry &censorstr;
               endlayout;
            endif;
         else
            if (PLOTTEST=1)
               layout gridded / rows=1 &insetopts;
                  %pValue
               endlayout;
            endif;
         endif;
         %end;

   %mend;

   %macro SurvTabHeader(multiple);
      %if &multiple %then %do; entry ""; %end;
      entry "";
      entry "";
      entry "";
      entry &r "Median";
      entry "";
      entry "";

      %if &multiple %then %do; entry ""; %end;
      entry &r "Subjects";
      entry &r "Event";
      entry &r "Censored";
      entry &r "Survival";
      entry &r PctMedianConfid;
      entry halign=left  "CL";
   %mend;

   %macro SurvivalTable;
      %local fmt r i t;
      %let fmt = bestd6.;
      %let r = halign = right;
      columnheaders;
         layout overlay / pad=(top=5);
            if(NSTRATA=1)
               layout gridded / columns=6 border=TRUE;
                  dynamic PctMedianConfid NObs NEvent Median
                          LowerMedian UpperMedian;
                  %SurvTabHeader(0)
                  entry &r NObs;
                  entry &r NEvent;
                  entry &r eval(NObs-NEvent);
                  entry &r eval(put(Median,&fmt));
                  entry &r eval(put(LowerMedian,&fmt));
                  entry &r eval(put(UpperMedian,&fmt));
               endlayout;
            else
               layout gridded / columns=7 border=TRUE;
                  dynamic PctMedianConfid;
                  %SurvTabHeader(1)
                  %do i = 1 %to 10;
                     %let t = / textattrs=GraphData&i;
                     dynamic StrVal&i NObs&i NEvent&i Median&i
                             LowerMedian&i UpperMedian&i;
                     if (&i <= nstrata)
                        entry &r StrVal&i &t;
                        entry &r NObs&i &t;
                        entry &r NEvent&i &t;
                        entry &r eval(NObs&i-NEvent&i) &t;
                        entry &r eval(put(Median&i,&fmt)) &t;
                        entry &r eval(put(LowerMedian&i,&fmt)) &t;
                        entry &r eval(put(UpperMedian&i,&fmt)) &t;
                     endif;
                  %end;
               endlayout;
            endif;
         endlayout;
      endcolumnheaders;
   %mend;

   %macro SurvivalSummaryTable;
      %macro AtRiskLatticeStart;
         layout lattice / columndatarange=union rowgutter=10
            rows=%if &outside %then 2 rowweights=ROWWEIGHTS;
                 %else              1;;
         %if &outside %then %do; cell; %end;
      %mend;

      %macro AtRiskLatticeEnd(useclassopts);
         %if &outside %then %do;
            endcell;
            cell;
               layout overlay / walldisplay=none xaxisopts=(display=none);
                  axistable x=TATRISK value=ATRISK / &atriskopts
                            %if &useclassopts ne %then &classopts;;
               endlayout;
            endcell;
         %end;
         %SurvivalTable
         endlayout;
      %mend;
   %mend;

   %macro AtRiskLatticeStart;
      %if &outside %then %do;
         layout lattice / rows=2 rowweights=ROWWEIGHTS
                          columndatarange=union rowgutter=10;
         cell;
      %end;
   %mend;

   %macro AtRiskLatticeEnd(useclassopts);
      %if &outside %then %do;
         endcell;
         cell;
            layout overlay / walldisplay=none xaxisopts=(display=none);
               axistable x=TATRISK value=ATRISK / &atriskopts
                         %if &useclassopts ne %then &classopts;;
            endlayout;
         endcell;
      endlayout;
      %end;
   %mend;

%CompileSurvivalTemplates
%mend;

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
