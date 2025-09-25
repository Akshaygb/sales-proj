public class RentalAutomationScheduler {
    
    public static void scheduleAllJobs() {
        // Unschedule any existing jobs first
        unscheduleAllJobs();
        
        try {
            // Schedule daily reminder job to run every day at 9 AM
            System.schedule('Daily Rental Reminders', '0 0 9 * * ?', new DailyRentalReminderScheduler());
            
            // Schedule weekly reminder job to run every day at 10 AM (batch will filter appropriately)
            System.schedule('Weekly Rental Reminders', '0 0 10 * * ?', new WeeklyRentalReminderScheduler());
            
            // Schedule monthly reminder job to run every day at 11 AM (batch will filter appropriately)  
            System.schedule('Monthly Rental Reminders', '0 0 11 * * ?', new MonthlyRentalReminderScheduler());
            
            // Schedule overdue monitor to run every day at 8 AM
            System.schedule('Overdue Contract Monitor', '0 0 8 * * ?', new OverdueContractMonitor());
            
            System.debug('All rental automation jobs have been scheduled successfully');
        } catch (Exception e) {
            System.debug('Error scheduling jobs: ' + e.getMessage());
        }
    }
    
    public static void unscheduleAllJobs() {
        List<String> jobNames = new List<String>{
            'Daily Rental Reminders',
            'Weekly Rental Reminders', 
            'Monthly Rental Reminders',
            'Overdue Contract Monitor'
        };
        
        try {
            List<CronTrigger> jobsToAbort = [
                SELECT Id 
                FROM CronTrigger 
                WHERE CronJobDetail.Name IN :jobNames
            ];
            
            for (CronTrigger job : jobsToAbort) {
                System.abortJob(job.Id);
            }
            
            System.debug('All existing rental automation jobs have been unscheduled');
        } catch (Exception e) {
            System.debug('Error unscheduling jobs: ' + e.getMessage());
        }
    }
    
    public static List<String> getScheduledJobStatus() {
        List<String> jobStatus = new List<String>();
        List<String> jobNames = new List<String>{
            'Daily Rental Reminders',
            'Weekly Rental Reminders', 
            'Monthly Rental Reminders',
            'Overdue Contract Monitor'
        };
        
        try {
            Map<String, CronTrigger> scheduledJobs = new Map<String, CronTrigger>();
            List<CronTrigger> jobs = [
                SELECT Id, CronJobDetail.Name, State, NextFireTime, PreviousFireTime
                FROM CronTrigger 
                WHERE CronJobDetail.Name IN :jobNames
            ];
            
            for (CronTrigger job : jobs) {
                scheduledJobs.put(job.CronJobDetail.Name, job);
            }
            
            for (String jobName : jobNames) {
                if (scheduledJobs.containsKey(jobName)) {
                    CronTrigger job = scheduledJobs.get(jobName);
                    jobStatus.add(jobName + ': SCHEDULED - Next: ' + job.NextFireTime + ' - State: ' + job.State);
                } else {
                    jobStatus.add(jobName + ': NOT SCHEDULED');
                }
            }
        } catch (Exception e) {
            jobStatus.add('Error retrieving job status: ' + e.getMessage());
        }
        
        return jobStatus;
    }
}
