//
// (c) 2013 Appirio, Inc.
//
// A controller for Intranet Curriculum Detail
//
// 31 Oct 2013     Sudhir Kr. Jagetiya       Original
//
public with sharing class IntranetModuleDetailController {

  private final static String ASSET_TYPE_ASSESSMENT;
  // Story S-206998 - By Hemlata
  private final static String ASSET_TYPE_PREASSESSMENT;
  
  static {
    ASSET_TYPE_ASSESSMENT = 'Assessment';
    // Story S-206998 - By Hemlata
    ASSET_TYPE_PREASSESSMENT = 'Pre Assessment';
  }

  private String currentUserLanguage;
  public Boolean showMoreForEnrolledUser {get; set;}

  public static ModuleWrapper moduleWrapperRecord {get; private set;}
  public List<CourseWrapper> courseWrapperList {get; private set;}

  public String errorMessage {get; private set;}
  public Boolean pageHasAnError {get; private set;}
  public Boolean noModuleAvailable {get; private set;}
  public Boolean noCourseAvailable {get; private set;}
  public Boolean isPrerequisiteCompleted {get; private set;}
  public boolean renderComment{get { return IntranetUtility.hasChatter();} private set;}    
  public String academyType {get { return IntranetUtility.getAcademyType();} private set;}
    
  public Integer percentProgressCompleted {get; set;}
  
  private List<Training_User__c> trainingUsers;
  private Module_Progress__c mProgress;
  private Id moduleId;
  private Id currentUserId;

  public IntranetModuleDetailController() {
    isPrerequisiteCompleted = true;
    currentUserId = UserInfo.getUserId();
    errorMessage = 'Errors: ';
    pageHasAnError = false;
    noModuleAvailable = false;
    noCourseAvailable = false;
    courseWrapperList = new List<CourseWrapper>();
    trainingUsers = new List<Training_User__c>();

    moduleId = ApexPages.currentPage().getParameters().get('Id');
    //init(curriculumId);
  }

  public PageReference initialize() {
    try {
        trainingUsers.clear();

        Training_User__c trainingUser;
        trainingUsers = [SELECT Id, Region__c, Language__c FROM Training_User__c WHERE User__c = :currentUserId];
        if(trainingUsers.size() == 0) {
          trainingUser = new Training_User__c(User__c = currentUserId);
          insert trainingUser;
        } else if(trainingUsers.size() > 0) {
          trainingUser = trainingUsers.get(0);
          currentUserLanguage = trainingUsers.get(0).Language__c;
        }

        Module__c module;
        if(moduleId == null) {
          errorMessage = System.Label.Intranet_Error_Message_404;
          noModuleAvailable = true;
          pageHasAnError = true;
          return null;
        } else {
        	// COMMENT OUT LINE BELOW TO ALLOW DEPLOYMENT
          //module = [SELECT Id, Name, Published_Date__c, Description__c, Prerequisite__c,
          module = [SELECT Id, Name, Summary__c, Published_Date__c, Description__c, Prerequisite__c, 
                               Due_Date__c, Total_Likes__c, View_Count__c, Curriculum__r.Name,
                               Curriculum__c
                          FROM Module__c
                         WHERE Id = :moduleId LIMIT 1];

          if(module == null) {
            errorMessage = System.Label.Intranet_Error_Message_404;
            noModuleAvailable = true;
            pageHasAnError = true;
            return null;
          } else {
            module.View_Count__c = module.View_Count__c == null ? 0 : module.View_Count__c;
            module.View_Count__c += 1;
            update module;
          }
        }
      
      
        List<Module_Progress__c> moduleProgressList = [SELECT Id, Due_Date__c, Date_Completed__c, Enrollment_Type__c, Percent_Complete__c
                                                        FROM Module_Progress__c
                                                       WHERE Training_User__c = :trainingUser.Id
                                                         AND Module__c = :moduleId];

        if(moduleProgressList.size() > 1) {
          errorMessage = System.label.There_is_more_than_one_Module_Progress_exist_for_this_Module;
          pageHasAnError = true;
          return null;
        } else if(moduleProgressList.size() == 0) {
          //mProgress = new Module_Progress__c(Module__c = moduleId, Training_User__c = trainingUser.Id);
          //insert mProgress;
          moduleWrapperRecord = new ModuleWrapper(module, null);
        } else {
          moduleWrapperRecord = new moduleWrapper(module, moduleProgressList.get(0));
        }
      
      if(module.Prerequisite__c != null) {
          for(Module_Progress__c moduleProgress : [SELECT Id, Status__c
                                                     FROM Module_Progress__c
                                                    WHERE Module__c = :module.Prerequisite__c
                                                      AND Training_User__c = :trainingUser.Id
                                                      AND Status__c != 'Complete']) {
            isPrerequisiteCompleted = false;
            return null;
          }
        }
        
        courseWrapperList.clear();
        //getting all published modules
        // COMMENT OUT LINE BELOW TO ALLOW DEPLOYMENT
        List<Course_Module__c> courseList = [SELECT Course__r.Total_Likes__c, Course__r.Summary__c, Course__r.Status__c,
        //List<Course_Module__c> courseList = [SELECT Course__r.Total_Likes__c, Course__r.Status__c,
                                                    Course__r.Start_Date__c, Sort_Order__c, Course__r.Published_Date__c,
                                                    Course__r.Name, Course__r.End_Date__c, Course__c, Prerequisite__r.Course__c, 
                                                            Course__r.Due_Date__c, Course__r.Description__c, Module__c
                                                       FROM Course_Module__c
                                                       WHERE Module__c = :moduleId
                                                        AND Course__r.IsPublished__c = true
                                                        AND Course__c != null
                                                        AND (Course__r.Region__c = null OR Course__r.Region__c = :trainingUser.Region__c)
                                                      ORDER By Sort_Order__c ASC];

        Set<Id> courseIds = new Set<Id>();
        Map<Id, Boolean> prerequisiteCourseModule = new Map<Id, Boolean>();
        for(Course_Module__c courseModule : courseList) {
             courseIds.add(courseModule.Course__c);
             if(courseModule.Prerequisite__r.Course__c != null) {
              prerequisiteCourseModule.put(courseModule.Prerequisite__r.Course__c, false);
             }
        }

        if(courseList.size() == 0) {
          noCourseAvailable = true;
          errorMessage = System.label.No_courses_available_Error_403_Record_is_currently_unavailable;
          pageHasAnError = true;
          return null;
        }

      Map<Id, Course_Progress__c> courseAndCourseProgressMap = new Map<Id, Course_Progress__c>();
        Map<Id, AssetAndAssessment> assetAndAssessmentMap = populateAssetAndAssementCount(courseIds);
        Map<String, List<String>> recordTagsMap = populateTagMap(courseIds);
        Map<Id, IntranetUtilityWithPrivileges.LikesCommentFollwerInfo> socialInfoMap = IntranetUtilityWithPrivileges.getSocialInfo(courseIds);
        CourseWrapper courseWrapper;

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
        }
        
        for(Course_Progress__c courseProgress : [SELECT Id, Status__c, Course__c
                                                   FROM Course_Progress__c
                                                  WHERE Course__c IN :prerequisiteCourseModule.keySet()
                                                    AND Training_User__c = :trainingUser.Id
                                                    AND Status__c = 'Complete']) {
        prerequisiteCourseModule.put(courseProgress.Course__c, true);
      }

        for(Course_Module__c courseModule : courseList) {
            if(courseAndCourseProgressMap.containsKey(courseModule.Course__c)) {
                courseWrapper = new CourseWrapper(courseModule.Course__r, courseAndCourseProgressMap.get(courseModule.Course__c));
            if(assetAndAssessmentMap.containsKey(courseModule.Course__c)) {
              courseWrapper.assetAndAssessmentCount = assetAndAssessmentMap.get(courseModule.Course__c);
            }
            if(recordTagsMap.containsKey(courseModule.Course__c)) {
              courseWrapper.tagList = recordTagsMap.get(courseModule.Course__c);
            }
            if(socialInfoMap.containsKey(courseModule.Course__c)) {
              courseWrapper.socialInfo = socialInfoMap.get(courseModule.Course__c);
            }
            if(prerequisiteCourseModule.containsKey(courseModule.Prerequisite__r.Course__c)) {
              if(prerequisiteCourseModule.get(courseModule.Prerequisite__r.Course__c)) {
                courseWrapper.isPrerequisiteCompleted = true;
              }
            } else {
              courseWrapper.isPrerequisiteCompleted = true;
            }
            courseWrapperList.add(courseWrapper);
            }
        }

        if(module != null && String.isNotEmpty(currentUserLanguage) && currentUserLanguage != 'English') {
        	// COMMENT OUT LINE BELOW TO ALLOW DEPLOYMENT
        	for(Module__c mod : [SELECT Total_Likes__c, Summary__c, Status__c, Start_Date__c,
            //for(Module__c mod : [SELECT Total_Likes__c, Status__c, Start_Date__c,
                                            Sort_Order__c, Published_Date__c, Name, End_Date__c,
                                            Due_Date__c, Description__c, Curriculum__c, Parent__c
                                                        FROM Module__c
                                                        WHERE Parent__c = : module.Id
                                                            AND Language__c = : currentUserLanguage]) {
                moduleWrapperRecord.alternateModule = mod;
            }

            set<Id> setOfCourseId = new set<Id>();
            Map<Id,Course__c> mapOfCourse = new Map<Id,Course__c>();

            for(CourseWrapper cw : courseWrapperList) {
                setOfCourseId.add(cw.course.Id);
            }
// COMMENT OUT LINE BELOW TO ALLOW DEPLOYMENT
			for(Course__c course : [SELECT Total_Likes__c, Summary__c, Status__c,
            //for(Course__c course : [SELECT Total_Likes__c, Status__c,
                                                    Start_Date__c,  Published_Date__c,
                                                    Name, End_Date__c, Id,
                                                    Due_Date__c, Description__c, Parent__c
                                                        FROM Course__c
                                                        WHERE Parent__c IN : setOfCourseId
                                                            AND Language__c = : currentUserLanguage]) {
                mapOfCourse.put(course.Parent__c,course);
            }

            for(CourseWrapper cw : courseWrapperList) {
                if(mapOfCourse.containsKey(cw.course.Id)) {
                    cw.alternateCourse = mapOfCourse.get(cw.course.Id);
                }
            }
         }
    }
    catch (Exception exce) {
        errorMessage = exce.getmessage();
    }
    return null;
  }

  private Map<Id, AssetAndAssessment> populateAssetAndAssementCount(Set<Id> courseIds) {
    Map<Id, AssetAndAssessment> assetAndAssessmentMap = new Map<Id, AssetAndAssessment>();
    for(Asset__c asset : [SELECT Course__c, Asset_Type__c
                           FROM Asset__c
                          WHERE Course__r.IsPublished__c = true
                            AND IsPublished__c = true
                            AND Course__c IN :courseIds]) {

          if(!assetAndAssessmentMap.containskey(asset.Course__c)) {
            assetAndAssessmentMap.put(asset.Course__c, new AssetAndAssessment());
          }
          if(ASSET_TYPE_ASSESSMENT.equalsIgnoreCase(asset.Asset_Type__c)) {
            assetAndAssessmentMap.get(asset.Course__c).totalAssessments += 1;
          }  // START - Story S-206998 - By Hemlata 
          else if (ASSET_TYPE_PREASSESSMENT.equalsIgnoreCase(asset.Asset_Type__c)) {
            assetAndAssessmentMap.get(asset.Course__c).totalPreAssessments += 1;
          }
          // END - Story S-206998 - By Hemlata 
          else {
            assetAndAssessmentMap.get(asset.Course__c).totalAssets += 1;
          }
    }

    return assetAndAssessmentMap;
  }

  private Map<String, List<String>> populateTagMap(Set<Id> recordIds) {
    Map<String, List<String>> recordTagsMap = new Map<String, List<String>>();
    for(Intranet_Content_Tags__c contentTag : [SELECT Course__c, Tags__r.Tag__c
                                                 FROM Intranet_Content_Tags__c
                                                WHERE Course__c IN :recordIds]) {
      if(!recordTagsMap.containskey(contentTag.Course__c)) {
        recordTagsMap.put(contentTag.Course__c, new List<String>());
      }
      recordTagsMap.get(contentTag.Course__c).add(contentTag.Tags__r.Tag__c);
    }
    return recordTagsMap;
  }


  public class CourseWrapper {
    public Course__c course {get; private set;}
    public Course__c alternateCourse {get; private set;}
    public Course_Progress__c courseProgress {get; private set;}
    public Boolean isPrerequisiteCompleted {get; private set;}
    public AssetAndAssessment assetAndAssessmentCount {get; private set;}
    public IntranetUtilityWithPrivileges.LikesCommentFollwerInfo socialInfo {get; private set;}
    public List<String> tagList {get; private set;}

    public CourseWrapper(Course__c course, Course_Progress__c courseProgress) {
      this.course = course;
      this.courseProgress = courseProgress;
      this.courseProgress.Percent_Complete__c = this.courseProgress.Percent_Complete__c == null ? 0 : this.courseProgress.Percent_Complete__c;
      this.assetAndAssessmentCount = new AssetAndAssessment();
      this.tagList = new List<String>();
      this.socialInfo = new IntranetUtilityWithPrivileges.LikesCommentFollwerInfo();
      this.isPrerequisiteCompleted = false;
    }
  }



  public class ModuleWrapper {
    public Module__c module {get; private set;}
    public Module__c alternateModule {get; private set;}
    public Module_Progress__c moduleProgress {get; private set;}

    public ModuleWrapper(Module__c module, Module_Progress__c moduleProgress) {
      this.module = module;
      if(moduleProgress != null) {
        this.moduleProgress = moduleProgress;
        this.moduleProgress.Percent_Complete__c = this.moduleProgress.Percent_Complete__c == null ? 0 : this.moduleProgress.Percent_Complete__c;
      }
    }
  }

  public class AssetAndAssessment {
    public Integer totalAssets {get; set;}
    public Integer totalAssessments {get; set;}
     // Story S-206998 - By Hemlata
    public Integer totalPreAssessments {get; set;}
    public AssetAndAssessment() {
      totalAssets = 0;
      totalAssessments = 0;
       // Story S-206998 - By Hemlata
      totalPreAssessments = 0;
    }
  }

}