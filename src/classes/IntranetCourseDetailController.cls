/**
  * Apex Class: IntranetCourseDetailController
  * Description: T-207157 : Intranet - Display Course information and related assets
  * Created By: Devendra Dhaka
  * Created Date: November 1st, 2013.
  * 
  * Modified By : Alka Taneja
  * Modified Date : 10 July, 2014
  * Case : 00088978 
  * Detail : Need to show the assests only if the user is enrolled for that course
  *
  * Modified by: Nicole Bock
  * August 7, 2014
  * S-219115: Adding logic for Getting Started course completion check 
  */
public without sharing class IntranetCourseDetailController{

    public final static String ENROLLMENT_TYPE_ELECTIVE {get; private set;}
    public final static String ASSET_PROGRESS_STATUS_COMPLETE {get; private set;}  
    public String academyType {get { return IntranetUtility.getAcademyType();} private set;}
    public  Boolean  isMedicalUser {get  {return IntranetUtility.isMedicalUser();}  set;}
    private final static Set<String> ENROLLMENT_TYPES_MANDATORY;
    public final static String ASSET_TYPE_ASSESSMENT{get;set;}
    // Story S-206998
    public final static String ASSET_TYPE_PREASSESSMENT {get;set;}
    private final static String ASSET_TYPE_URL;
    private final static String ASSET_TYPE_ATTACHMENT;
    private final static String ASSET_MEDIA_TYPE_SCORM;
    private final static String ASSET_MEDIA_TYPE_VIDEO;
    private final static String ASSET_PROGRESS_STATUS_IN_PROGRESS;
    private final static String QUESTION_STATUS_ACTIVE;
    Private Static BrightCove_Credentials__c brightCove;
    public boolean renderComment{get { return IntranetUtility.hasChatter();} private set;}
    private String currentUserLanguage;

    static {
        ENROLLMENT_TYPES_MANDATORY = new Set<String>{'Mandatory', 'Recommended'};
        ENROLLMENT_TYPE_ELECTIVE = 'Elective';
        ASSET_TYPE_ATTACHMENT = 'Attachment';
        ASSET_TYPE_URL = 'URL';
        ASSET_TYPE_ASSESSMENT = 'Assessment';
        // Story S-206998
        ASSET_TYPE_PREASSESSMENT = 'Pre Assessment'; 
        ASSET_PROGRESS_STATUS_COMPLETE = 'Complete';
        ASSET_PROGRESS_STATUS_IN_PROGRESS = 'In Progress';
        QUESTION_STATUS_ACTIVE = 'Active';
        ASSET_MEDIA_TYPE_SCORM = 'SCORM';
        ASSET_MEDIA_TYPE_VIDEO = 'Video';
    }

    public Course_Progress__c courseProgress {get;set;}
    public Course__c course {get;set;}
    public Course__c alternateCourse {get;set;}
    public List<AssetWrapper> assetsList{ get; set;}
    public List<AssetWrapper> assessmentList{ get; set;}
    public List<AssetWrapper> combinedAssets {get;set;}
    public Integer currentRecordIndex {get; set;}
    public Boolean isAssessment {get; set;}
    public Boolean isPrerequisiteCompleted {get; private set;}
    public Boolean showMoreForEnrolledUser {get; set;}
    public String errorMessage {get; private set;}
    public Boolean pageHasAnError {get; private set;}
    public Integer percentageAssetCompleteAssessmentType{get;set;}{percentageAssetCompleteAssessmentType = 0;}
    public Integer percentageAssetCompleteNonAssessmentType{get;set;}{percentageAssetCompleteNonAssessmentType = 0;}
    //Logged in user
    private Training_User__c trainingUser;
    private String courseId;
    public String userAgent {get;set;}
    // Story S-206783 - START - By Hemlata
    public String moduleId {get;set;}
    public String moduleName{get;set;}
    public String curriculumId {get;set;}
    public String curriculumName{get;set;}
    public String courseSortOrder;
    List<Course_Module__c> courseList = new List<Course_Module__c>();
    Map<Id, Course_Progress__c> courseAndCourseProgressMap = new Map<Id, Course_Progress__c>(); 
    public String toMove;
    //NBOCK S-219115 
    public boolean gettingStartedCheck {get;set;}

    public String getToMove() {
        return toMove;
    }

    public void setToMove(String s)
    {
     system.debug('s**'+s);
     toMove = s;
    }
  
  
    // Story S-206783 - END
    // Story S-206998 - START - By Hemlata
    public List<AssetWrapper> preAssessmentList{ get; set;}
     public Boolean isPreAssessment {get; set;}
     public Boolean isPreAssesmentTaken {get;set;}
    // END S-206998

    //Constructor
    private Set<Id> setOfAssetIds;
    public IntranetCourseDetailController() {
        List<BrightCove_Credentials__c> brightCoveList = BrightCove_Credentials__c.getAll().values();
        if(!brightCoveList.isEmpty())
            brightCove=brightCoveList[0];
        isPrerequisiteCompleted = true;
        assetsList = new List<AssetWrapper>();
        courseList = new List<Course_Module__c>();  
        courseAndCourseProgressMap = new Map<Id, Course_Progress__c>();  
        // Story S-206998  - By Hemlata
        isPreAssesmentTaken = false;
    }

    public void getCourseInfo() {
      setOfAssetIds = new Set<Id>();
      courseProgress = null;
      
      //Get Id passed in the URL
      courseId = Apexpages.currentPage().getParameters().get('Id');
      
      userAgent = ApexPages.currentPage().getHeaders().get('USER-AGENT');
            
      //If ID is available then fetch the information
      if(courseId != null){
        try{
          list<course__c> courseList = new list<course__c>([SELECT Id, Description__c, Name, Published_Date__c,
                           View_Count__c, Allow_Self_Enroll__c
                          FROM Course__c
                         WHERE Id = :courseId LIMIT 1]);
            course = courseList == null ? null : courseList.get(0);
            //Get training user id
            trainingUser = getTrainingUser();
            currentUserLanguage = trainingUser.Language__c;

              if(course != null && String.isNotEmpty(currentUserLanguage) && currentUserLanguage != 'English') {
                       for(Course__c altCourse : [SELECT Id, Description__c, Name, Published_Date__c,
                                                         View_Count__c, Allow_Self_Enroll__c
                                          FROM Course__c
                                         WHERE Parent__c = :course.Id
                                           AND Language__c = :currentUserLanguage LIMIT 1]){
                 alternateCourse = altCourse;
             }
          }

          if(course.View_Count__c == null) {
            course.View_Count__c = 1;
          } else {
            course.View_Count__c += 1;
          }

          update course;
          
                    
          //NBOCK S-219115 start
          List<Course_Progress__c> gettingStartedList = new List<Course_Progress__c>();
          gettingStartedList = [SELECT Id FROM Course_Progress__c WHERE Training_User__c=: trainingUser.Id AND Course__r.Id=: System.Label.GettingStartedId  AND Status__c = 'Complete'];
          if(trainingUser.Academy__c == 'Medical academy'){
            if((gettingStartedList.IsEmpty()) && course.Id != System.Label.GettingStartedId){
              gettingStartedCheck = true;
            }
            else {
              gettingStartedCheck = false;
            }
          }
 
             system.debug('######' + trainingUser);
          system.debug('gscheck' + gettingStartedCheck);
          system.debug('gslist' + gettingStartedList);
        // Story S-206783 - START - By Hemlata
          List<Course_Module__c> cModuleList = [SELECT Id, sort_order__c, module__c, module__r.Name,module__r.Curriculum__c, module__r.curriculum__r.Name, Course__c FROM Course_Module__c WHERE Course__c = :courseId];
          if (cModuleList != null && cModuleList.size() >= 1) {
             courseSortOrder = cModuleList[0].sort_order__c;
             moduleId = cModuleList[0].module__c;
             moduleName = cModuleList[0].module__r.Name;
             curriculumId = cModuleList[0].module__r.Curriculum__c;
             curriculumName = cModuleList[0].module__r.curriculum__r.Name;           
          }
          // Story S-206783 - END 
          
          List<Course_Module__c> courseModuleList = [SELECT Id, Prerequisite__r.Course__c, Course__c FROM Course_Module__c WHERE Course__c = :courseId AND Prerequisite__r.Course__c != null LIMIT 1];
          if(courseModuleList.size() > 0) {
            for(Course_Progress__c cProgress : [SELECT Status__c
                                                FROM Course_Progress__c
                                               WHERE Course__c = :courseModuleList.get(0).Prerequisite__r.Course__c
                                                 AND Training_User__c=:trainingUser.Id 
                                                 AND Status__c != 'Complete' LIMIT 1]) {
              isPrerequisiteCompleted = false;
              return;
            }
            
          }
          //Get course progress for current course
          for(Course_Progress__c cProgress : [SELECT Due_Date__c, Enrollment_Type__c,Percent_Complete__c
                                                FROM Course_Progress__c
                                               WHERE course__c=:course.id
                                                 AND Training_User__c=:trainingUser.Id LIMIT 1]) {
              courseProgress = cProgress;
              courseProgress.Percent_Complete__c = courseProgress.Percent_Complete__c != null ? courseProgress.Percent_Complete__c : 0;
          }
          
          // Added if condition for the case #00088978 
          if(courseProgress != null) {
            getAssetsInfo();
          }
          

          if(String.isNotEmpty(currentUserLanguage) && !currentUserLanguage.equalsIgnoreCase('English')) {

                 Map<Id,Asset__c> mapOfAsset = new Map<Id,Asset__c>();

                     for(Asset__c ass : [SELECT Id,Name,Sort_Order__c,Summary__c,Duration__c,
                                      Media_Type__c,File_Size__c, Asset_Type__c, URL__c, Parent__c,BrightCove_ID__c, (SELECT id from attachments order by lastmodifieddate desc limit 1),Assessment__c
                                                                FROM Asset__c
                                                                WHERE Parent__c IN :setOfAssetIds
                                                                    AND isPublished__c = true
                                                                    AND Language__c = :currentUserLanguage]) {
                        mapOfAsset.put(ass.Parent__c,ass);
                    }
                    for(AssetWrapper cw : assetsList) {
                            if(mapOfAsset.containsKey(cw.asset.Id)) {
                                cw.alternateAsset = mapOfAsset.get(cw.asset.Id);
                                if (mapOfAsset.get(cw.asset.Id).attachments.size() > 0)
                                  cw.directURL ='/servlet/servlet.FileDownload?file='+mapOfAsset.get(cw.asset.Id).attachments.get(0).id;
                            }
                      }
//Added By : M Nargis,Cognizant AM Team for Fixing Up the Dual Tree Issue                     
                    for(AssetWrapper cw : assessmentList) {
                            if(mapOfAsset.containsKey(cw.asset.Id)) {
                                cw.alternateAsset = mapOfAsset.get(cw.asset.Id);
                            }
                    }  //End
                  }
        }
        catch(Exception e) {}
      }
    }


    public void getAssetsInfo(){
      try{
        assetsList = new List<AssetWrapper>();
        assessmentList = new List<AssetWrapper>();
        combinedAssets = new List<AssetWrapper>();
        Map<Id, Boolean> prerequisiteAsset = new Map<Id, Boolean>();
         // Story S-206998 - START - By Hemlata
        preAssessmentList = new List<AssetWrapper>();
        Map<Id,List<Edgeforce_Student_Assessment__c>> MapAssessmentTOStudents= new Map<Id,List<Edgeforce_Student_Assessment__c>>();     
        system.debug('trainingUser.id**' +trainingUser.id);
        for (Edgeforce_Student_Assessment__c stAss : [Select  User__c,Submitted_Time__c, Assessment__c,isPreAssessment__c, isSubmitted__C, Assessment_Notes__c,End_Time__c, Score__c, Name,Id, Grade__c,Assessment__r.Passing_Grade__c // Added by Hemlata -S-195423
                                                        From Edgeforce_Student_Assessment__c
                                                        Where  User__C =:trainingUser.User__c and isPreAssessment__c = true]) {
           if (!MapAssessmentTOStudents.containsKey(stAss.Assessment__c)) {
                MapAssessmentTOStudents.put(stAss.Assessment__c, new List<Edgeforce_Student_Assessment__c>{stAss});
           } else {
                MapAssessmentTOStudents.get(stAss.Assessment__c).add(stAss);
           }
         }
        // END

// Now we cache the list of any alternative assets belonging to this course
        map<id, asset__c> altAssets = new map<id, asset__c>();
        if(course != null && String.isNotEmpty(currentUserLanguage) && currentUserLanguage != 'English')
        {
             for(asset__c altAsset : [SELECT parent__c, Id,Name,Sort_Order__c ,Summary__c,Duration__c, Prerequisite__c, 
                           Media_Type__c,File_Size__c, Asset_Type__c, URL__c, LastModifiedDate,
                           Assessment__c, Assessment__r.Name, Assessment__r.Description__c,BrightCove_ID__c,
                                assessment__r.can_resit__c,
                                   (SELECT Id FROM Attachments),
                                   (Select Percent_Complete__c, Status__c
                                       From Asset_Progresses__r
                                       Where Training_User__c=:trainingUser.id Limit 1)
                                           From Asset__c
                                           Where parent__r.course__c=:course.id
                                                AND isPublished__c = true
                                                AND Language__c = :currentUserLanguage
                                                AND isPublished__c = true
                                            Order By Sort_Order__c ASC])
          {
                 altAssets.put(altAsset.parent__c, altAsset);
          }
        }
        system.debug('#### altAssets='+altAssets);
        for(Asset__c asset : [SELECT Id,Name,Sort_Order__c ,Summary__c,Duration__c, Prerequisite__c, 
                                     Media_Type__c,File_Size__c, Asset_Type__c, URL__c, LastModifiedDate,
                                     Assessment__c, Assessment__r.Name, Assessment__r.Description__c,BrightCove_ID__c,
                                             assessment__r.can_resit__c,
                                             (SELECT Id FROM Attachments),
                                             (Select Percent_Complete__c, Status__c
                                                 From Asset_Progresses__r
                                                 Where Training_User__c=:trainingUser.id Limit 1)
                                                     From Asset__c
                                                     Where Course__c=:course.id
                                                          AND isPublished__c = true
                                                      Order By Sort_Order__c ASC])
        {
          setOfAssetIds.add(asset.Id);
          if (!ASSET_TYPE_PREASSESSMENT.equalsIgnoreCase(asset.Asset_Type__c)) {
            if(altAssets.get(asset.Id)==null) // No alternative language
              combinedAssets.add(new AssetWrapper(asset,'Combined'));
            else // Alternative asset
              combinedAssets.add(new AssetWrapper(altAssets.get(asset.Id),'Combined'));
          } 

            if(asset.Prerequisite__c != null && !prerequisiteAsset.containsKey(asset.Prerequisite__c)) {
                prerequisiteAsset.put(asset.Prerequisite__c, false);
            }
            if(ASSET_TYPE_ASSESSMENT.equalsIgnoreCase(asset.Asset_Type__c)) {
                if(asset.Assessment__c != null) {
                  assessmentList.add(new AssetWrapper(asset));
                  System.debug('assessmentList' + assessmentList);

                }
            }
            // START - Story S-206998 By Hemlata            
            else if (asset.Asset_Type__c != null && ASSET_TYPE_PREASSESSMENT.equalsIgnoreCase(asset.Asset_Type__c)) {
               if ( IntranetUtility.isMedicalUser()) {
                if (isPreAssesmentTaken) {
                    continue;
                }
                if(asset.Assessment__c != null) {
                  preAssessmentList.add(new AssetWrapper(asset));
                  List<Asset_Progress__c> assetProgressList = asset.Asset_Progresses__r;
                  if (assetProgressList == null) {
                    isPreAssesmentTaken = false;
                  } else if (assetProgressList != null && assetProgressList.size() > 0) {
                        if (MapAssessmentTOStudents != null && asset.Assessment__c != null && MapAssessmentTOStudents.containsKey(asset.Assessment__c)) {
                            isPreAssesmentTaken = false;
                            for(Edgeforce_Student_Assessment__c stAss: MapAssessmentTOStudents.get(asset.Assessment__c)) {
                                if (stAss.isSubmitted__c) {
                                    isPreAssesmentTaken = true;
                                    break;
                                } 
                            } // for
                        }   
                  }
                }
            }   
            }
            // END 

            else {
              assetsList.add(new AssetWrapper(asset));
            }
        }
        
         // START Story S-206998 By Hemlata on [20/04]
        if (preAssessmentList != null && preAssessmentList.size() == 0) {
                isPreAssesmentTaken = true;
        }
          
          // END
        
        for(Asset_Progress__c assetProgress : [SELECT Id, Status__c, Asset__c
                                                   FROM Asset_Progress__c
                                                  WHERE Asset__c IN :prerequisiteAsset.keySet()
                                                    AND Training_User__c = :trainingUser.Id
                                                    AND Status__c = 'Complete']) {
          prerequisiteAsset.put(assetProgress.Asset__c, true);
        }
        setPrerequisiteCompletedCheck(assetsList, prerequisiteAsset);
        setPrerequisiteCompletedCheck(assessmentList, prerequisiteAsset);
        setPrerequisiteCompletedCheck(combinedAssets, prerequisiteAsset);
        
        
      } catch (Exception e){
        ApexPages.Message msg = new ApexPages.Message(Apexpages.Severity.ERROR, 'Error while getting list of assets. Please contact your administrator '+e.getMessage()+' '+e.getStackTraceString());
        ApexPages.addMessage(msg);
      }
    }

    private void setPrerequisiteCompletedCheck(List<AssetWrapper> assetsList, Map<Id, Boolean> prerequisiteAsset) {
        for(AssetWrapper assetwrapper : assetsList) {
          if(prerequisiteAsset.containsKey(assetwrapper.asset.Prerequisite__c)) {
            if(prerequisiteAsset.get(assetwrapper.asset.Prerequisite__c)) {
              assetWrapper.isPrerequisiteCompleted = true;
            }
          } else {
            assetWrapper.isPrerequisiteCompleted = true;
          }
        }
    }
    
    
    public Training_User__c getTrainingUser() {
        Training_User__c trainingUser;
        List<Training_User__c> trainingUserList = [SELECT id, Language__c, Region__c,User__c, Academy__c
                                                    FROM Training_User__c
                                                    WHERE User__c = :Userinfo.getUserId() Limit 1];
        if(trainingUserList != null && trainingUserList.size() > 0){
        trainingUser=trainingUserList[0];
        }
        else{
        trainingUser = new Training_User__c();
        trainingUser.User__c = Userinfo.getUserID();
        insert trainingUser;
        }
        return trainingUser;
    }

    public PageReference updateAssetProgress() {
        Id currentAssetId, assessmentId, currentUserId,alternateAssetId;
        String progressStatus;
      
      // For case #00088978 
      Boolean isDirectLink = false;
      
      Integer percentComplete;
      //Edgeforce_Student_Assessment__c edgeForceStudentAssessment;
        try {
            if(isAssessment) {
                progressStatus = ASSET_PROGRESS_STATUS_IN_PROGRESS;
                percentComplete = 0;
               // START S-206998 By Hemlata
                if (isPreAssessment) {
                    if(preAssessmentList.size() > currentRecordIndex) {
                        currentUserId = UserInfo.getUserId();
                        currentAssetId = preAssessmentList.get(currentRecordIndex).asset.Id;
                        isDirectLink = preAssessmentList.get(currentRecordIndex).isDirectLink;
                        assessmentId = preAssessmentList.get(currentRecordIndex).asset.Assessment__c; 
                    }
                } else {
                    if(assessmentList.size() > currentRecordIndex) {
                        currentUserId = UserInfo.getUserId();
                        isDirectLink = assessmentList.get(currentRecordIndex).isDirectLink;
                        currentAssetId = assessmentList.get(currentRecordIndex).asset.Id;
//Added By Nargis M,Cognizant AM Team for Dual Tree Issue                       
                        if(assessmentList.get(currentRecordIndex).alternateAsset != null){
                            assessmentId = assessmentList.get(currentRecordIndex).alternateAsset.Assessment__c;
                            alternateAssetId = assessmentList.get(currentRecordIndex).alternateAsset.Id;
                        }   
                        else{   
                            assessmentId = assessmentList.get(currentRecordIndex).asset.Assessment__c; 
                        }   
                    }
                } 
             // END S-206998    
            } else  {
                progressStatus = ASSET_PROGRESS_STATUS_COMPLETE;
                percentComplete = 100;
                if(assetsList.size() > currentRecordIndex) {
            currentAssetId = assetsList.get(currentRecordIndex).asset.Id;
            isDirectLink = assetsList.get(currentRecordIndex).isDirectLink;
          }
            }
                          
            List<Asset_Progress__c> listAssetProgress = [SELECT Date_Completed__c, Status__c
                                                           FROM Asset_Progress__c
                                                          WHERE (Asset__c = :currentAssetId OR Asset__c = : alternateAssetId) AND Training_User__c = :trainingUser.Id];
            
            for(Asset_Progress__c assetProgress : listAssetProgress) {
                assetProgress.Status__c = progressStatus;
                assetProgress.Date_Completed__c = isAssessment ? null : System.now();
                assetProgress.Percent_Complete__c = percentComplete;
            }
            if(listAssetProgress.size() == 0) {
                Asset_Progress__c assetProgress =  new Asset_Progress__c(Training_User__c = trainingUser.Id, Asset__c = currentAssetId,
                                  Status__c = progressStatus, Date_Completed__c = isAssessment ? null : System.now(), Percent_Complete__c = percentComplete);
                listAssetProgress.add(assetProgress);
                if(alternateAssetId != null)
                {
                Asset_Progress__c assetProgressAlt =  new Asset_Progress__c(Training_User__c = trainingUser.Id, Asset__c = alternateAssetId,
                                  Status__c = progressStatus, Date_Completed__c = isAssessment ? null : System.now(), Percent_Complete__c = percentComplete);
                listAssetProgress.add(assetProgressAlt);
                
                }
            }
            upsert listAssetProgress;
        }
        catch (Exception excp) {}

        if(!isDirectLink) {
            if(isAssessment) {
                system.debug('Return with initiateExamProcess(assessmentId);' + assessmentId);
              return initiateExamProcess(assessmentId);
            } else {
                return new PageReference('/apex/IntranetAssetDetail?id='+currentAssetId);
            }
        }
        
        System.debug('Return with null');
        return null;
    }

    public PageReference unEnrollUser() {
        try {
          List<sObject> recordsToBeDeleted = new List<sObject>();

          Set<Id> enrolledCourseIds = new Set<Id>();
          for(Course_Progress__c courseProgress : [SELECT Id, Course__c FROM Course_Progress__c
                                              WHERE Training_User__c = :trainingUser.Id
                                                AND Course__c = :courseId
                                                AND Enrollment_Type__c NOT IN :ENROLLMENT_TYPES_MANDATORY]) {
             recordsToBeDeleted.add(courseProgress);
             enrolledCourseIds.add(courseProgress.Course__c);
          }


          List<sObject> assetProgress = [SELECT Id FROM Asset_Progress__c
                                              WHERE Training_User__c = :trainingUser.Id
                                                AND Asset__r.Course__c IN :enrolledCourseIds];
          recordsToBeDeleted.addAll(assetProgress);

          delete recordsToBeDeleted;
          
          getCourseInfo();
          
          // Start for the case #00088978 
            pagereference pr = new Pagereference('/apex/IntranetCourseDetail?id='+course.id );
          pr.setredirect(True);
          return pr;
            // End for the case #00088978 
          
        } catch (Exception excep) { }
        return null;
    }

    public Pagereference enrollUser() {

        Boolean requestEmail = !course.Allow_Self_Enroll__c;
        String message = IntranetEnrollTrainingUsers.enrollUser(course.id,'Course',requestEmail);
        if(requestEmail){
        errorMessage = message;
        pageHasAnError = true;
        }
        else{
        if(String.isBlank(message)){
            pagereference pr = new Pagereference('/apex/IntranetCourseDetail?id='+course.id );
            pr.setredirect(True);
            return pr;
        }
        else{
            errorMessage = message;
            pageHasAnError = true;
        }
        }
      return null;
    }

    //initiate exam process
    private PageReference initiateExamProcess(Id selectedExamId) {
          Pagereference initiateAssessmentPage;
        //getting exam detals based on id
        EdgeforceAssessmentController edgeForceAssessmentCntrl = new EdgeforceAssessmentController();
        Edgeforce_Assessment__c selectedExam  = edgeForceAssessmentCntrl.getExamDetailsbyId(selectedExamId);
        
        //process questions to be displayed on UI
        List<Edgeforce_Questions__c> listofQuestionsforExamSet = edgeForceAssessmentCntrl.processRandomQuestionsforUser(selectedExam);

        if(listofQuestionsforExamSet <> null && listofQuestionsforExamSet.size() > 0){
            //storing tracker
            Edgeforce_Student_Assessment__c userExamTracker = new Edgeforce_Student_Assessment__c();
            userExamTracker.set__c = Integer.valueof(edgeForceAssessmentCntrl.assessmentSetNumber);
            //userExamTracker.Name = selectedExam.Name+' : '+userinfo.getFirstName()+' : '+system.now();
            userExamTracker.Assessment__c = selectedExam.Id;
            userExamTracker.User__c = userinfo.getUserId();
            if(userExamTracker.User__c <> null)
                userExamTracker.Student__c =  [Select contactid from user where id=:userExamTracker.User__c].contactid;
            userExamTracker.End_Time__c =  System.Now().addMinutes(Integer.valueof(selectedExam.Time_Limit__c)) ;
            if (isPreAssessment) {
             userExamTracker.isPreAssessment__c = true;
            }
            
            try{
                 Database.insert(userExamTracker);
            }catch(Exception e){
                // ApexAuditLog.createLogAndSave('AssessmentController','initiateExamProcess', e.getStackTraceString(), e);
            }

            List<Edgeforce_Student_Assessment_Questions__c> listofUserExamQuestions = new List<Edgeforce_Student_Assessment_Questions__c>();

            if(userExamTracker <> null &&userExamTracker.id <> null){
                //storing all questions to maintain state during exam process

                Integer sequence = 1;
                for(Edgeforce_Questions__c examQuesionData:listofQuestionsforExamSet){
                    Edgeforce_Student_Assessment_Questions__c userexamQuestiontoStore = new Edgeforce_Student_Assessment_Questions__c();
                    userexamQuestiontoStore.Sequence__c = sequence;
                    userexamQuestiontoStore.Student_Assessment__c = userExamTracker.Id;
                    userexamQuestiontoStore.student__c = userExamTracker.Student__c;
                    userexamQuestiontoStore.Questions__c = examQuesionData.Id;
                    sequence = sequence+1;
                    listofUserExamQuestions.add(userexamQuestiontoStore);
                }

                try{
                    Database.insert(listofUserExamQuestions);
                }catch(Exception e){
                  // ApexAuditLog.createLogAndSave('AssessmentController','initiateExamProcess', e.getStackTraceString(), e);
                }

            }

            //if there are questions then redirect to exam page and passing examtrackerid in parameter
            if(userExamTracker <> null && listofUserExamQuestions <> null && userExamTracker.Id <> null && listofUserExamQuestions.size()>0){

              initiateAssessmentPage = Page.EdgeforceAssessment;
              initiateAssessmentPage.getParameters().put('examId', userExamTracker.Id);
                // Story S-206998 -  By Hemlata
              initiateAssessmentPage.getParameters().put('isPreAssessment', String.valueOf(isPreAssessment));
              initiateAssessmentPage.setRedirect(true);

            }else{
                initiateAssessmentPage = null;
            }
        }else{

            initiateAssessmentPage = null;
        }
         
         return initiateAssessmentPage;
    }

 // Story S-206783 - START - By Hemlata
    private void getCoursesOfModules(String orderByValue) {
        if (orderByValue == 'ASC') {
        courseList = [SELECT Course__r.Total_Likes__c, Course__r.Summary__c, Course__r.Status__c,
                                                  Course__r.Start_Date__c, Sort_Order__c, Course__r.Published_Date__c,
                                                  Course__r.Name, Course__r.End_Date__c, Course__c, Prerequisite__r.Course__c, 
                                                  Course__r.Due_Date__c, Course__r.Description__c, Module__c
                                             FROM Course_Module__c
                                             WHERE Module__c = :moduleId
                                              AND Course__r.IsPublished__c = true
                                              AND Course__c != null
                                              AND (Course__r.Region__c = null OR Course__r.Region__c = :trainingUser.Region__c)
                                            ORDER By Sort_Order__c ASC];
       } else  if (orderByValue == 'DESC') {
        courseList = [SELECT Course__r.Total_Likes__c, Course__r.Summary__c, Course__r.Status__c,
                                                  Course__r.Start_Date__c, Sort_Order__c, Course__r.Published_Date__c,
                                                  Course__r.Name, Course__r.End_Date__c, Course__c, Prerequisite__r.Course__c, 
                                                  Course__r.Due_Date__c, Course__r.Description__c, Module__c
                                             FROM Course_Module__c
                                             WHERE Module__c = :moduleId
                                              AND Course__r.IsPublished__c = true
                                              AND Course__c != null
                                              AND (Course__r.Region__c = null OR Course__r.Region__c = :trainingUser.Region__c)
                                            ORDER By Sort_Order__c DESC];
       }                                      
                Set<Id> courseIds = new Set<Id>();
               for(Course_Module__c courseModule : courseList) {
                        courseIds.add(courseModule.Course__c);
                } // for                
                List<Course_Progress__c> courseProgressList = [SELECT Id, Due_Date__c, Date_Completed__c, Training_User__c, Percent_Complete__c,
                                                            Enrollment_Type__c, Date_Started__c, Course__c, Status__c, Region_Lock__c
                                                       FROM Course_Progress__c
                                                      WHERE Course__c IN :courseIds
                                                        AND Course__r.IsPublished__c = true
                                                        AND Training_User__c = :trainingUser.Id];
                for(Course_Progress__c courseProgress : courseProgressList) {
                    if(!courseAndCourseProgressMap.containsKey(courseProgress.Course__c)) {
                        courseAndCourseProgressMap.put(courseProgress.Course__c, courseProgress);
                    }
                } // for
    }
    
    public  pageReference goToNextPreviousCourse(){
      // String toMove =Apexpages.currentPage().getParameters().get('toMove');
       system.debug('toMove**'+toMove); 
        PageReference pageRef = null;
        try{
            if (courseSortOrder != null) {
                String sortOrder;
                courseList = new List<Course_Module__c>();
                courseAndCourseProgressMap = new Map<Id, Course_Progress__c>(); 
                if (toMove == 'Next') {
                    sortOrder = String.valueOf(Integer.ValueOf(courseSortOrder)+1);
                    getCoursesOfModules('ASC');
                } else if (toMove == 'Previous') { 
                    sortOrder = String.valueOf(Integer.ValueOf(courseSortOrder)-1);
                     getCoursesOfModules('DESC');
                }    
                
                 
                for(Course_Module__c courseModule : courseList) {
                     system.debug('courseModule **'+courseModule );  
                       system.debug('sortOrder  **'+sortOrder  );      
                    if(courseAndCourseProgressMap.containsKey(courseModule.Course__c) && courseModule.Sort_Order__c == sortOrder) {
                          pageRef = new PageReference('/apex/IntranetCourseDetail?id='+courseModule.Course__c);
                         pageRef.setRedirect(true); 
                        return pageRef;
                    } else if (!courseAndCourseProgressMap.containsKey(courseModule.Course__c) && courseModule.Sort_Order__c == sortOrder) {
                        if (toMove == 'Next') {
                            sortOrder = String.valueOf(Integer.ValueOf(sortOrder)+1);
                        } else if (toMove == 'Previous') { 
                                sortOrder = String.valueOf(Integer.ValueOf(sortOrder)-1);
                        }  
                       
                    }
                }
              }  
             pageRef = new PageReference('/apex/IntranetModuleDetail?id='+moduleId);              
            pageRef.setRedirect(true);   
                            
        }catch(Exception e){
            pageRef = new PageReference('/apex/IntranetModuleDetail?id='+moduleId);
            pageRef.setRedirect(true);   
        }
        return pageRef;
        
    }

    public String getScormURL(Asset__c asset) {
      return IntranetUtility.getScormUrl(asset.id); 
    } 

    // Story S-206783 - END - By Hemlata

// DJ 19th May 2014: moved to its own public apex class as this is used in a few places
    /**********
        This class is wrapper for the assets
    **********/
   /* public Class AssetWrapper{
        public Asset__c asset{get;set;}
        public Asset__c alternateAsset{get;set;}
        public Asset_Progress__c assetProgress{get;set;}
        public Boolean isPrerequisiteCompleted {get; set;}
        public Boolean canresit {get; private set;}
        // This displays the string in Hour and minutes format
        public String durationString{get;set;}
        public Boolean isDirectLink {get; set;}
        public String directURL {get; set;}
        public AssetWrapper(Asset__c asset){
            this.asset=asset;
            this.asset.Duration__c = asset.Duration__c != null ? asset.Duration__c : 0;
            this.durationString = convertDuration(asset.Duration__c);
            this.isDirectLink = false;
            this.isPrerequisiteCompleted = false;
            if(asset.Asset_Progresses__r!=Null && asset.Asset_Progresses__r.size()>0)
                this.assetProgress=asset.Asset_Progresses__r[0];

            if(asset.Asset_Type__c != null) {
                if(ASSET_TYPE_ATTACHMENT.equalsIgnoreCase(asset.Asset_Type__c) && asset.Attachments.size() == 1) {
                    this.isDirectLink = true;
                    this.directURL = '/servlet/servlet.FileDownload?file=' + asset.Attachments.get(0).Id;
                } else if(ASSET_TYPE_URL.equalsIgnoreCase(asset.Asset_Type__c)){
                    this.isDirectLink = true;
                    this.directURL = asset.URL__c;
                }
            }
            if(asset.Media_Type__c != null && (ASSET_MEDIA_TYPE_SCORM.equalsIgnoreCase(asset.Media_Type__c) )) {
                
                this.isDirectLink = true;
                this.directURL = '/apex/EdgeForceScormViewer?id='+asset.Id;
            }
            else if(asset.Media_Type__c != null && ASSET_MEDIA_TYPE_VIDEO.equalsIgnoreCase(asset.Media_Type__c)){
                this.isDirectLink = true;
                this.directURL ='/apex/IntranetBrightCoveVideo?vid='+asset.BrightCove_ID__c+'&pid='+brightCove.Player_Id__c+'&pkey='+brightCove.Player_Key__c;
            }

            if (Asset.assessment__c!= null){
                this.canresit = asset.assessment__r.can_resit__c;
            }
        }

        public AssetWrapper(Asset__c asset,String mode){
            this.asset=asset;
            if(asset.Asset_Progresses__r!=Null && asset.Asset_Progresses__r.size()>0)
                this.assetProgress=asset.Asset_Progresses__r[0];
        }

        //Converts the duration number into hours and minutes formated string
        private String convertDuration(Decimal durationNumber){
          String durationString= '';
          Integer duration=Integer.valueOf(durationNumber);
          if(Math.ceil(duration/60) > 0)
            durationString+= Integer.valueOf(Math.ceil(duration/60)) +' Hours ';
          durationString+= Math.mod(duration,60) +' Minutes';
          return durationString;
        }
    }*/ 

}