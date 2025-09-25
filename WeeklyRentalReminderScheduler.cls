public class WeeklyRentalReminderScheduler implements Schedulable {
    
    public void execute(SchedulableContext ctx) {
        RentalReminderBatch weeklyBatch = new RentalReminderBatch('Weekly');
        Database.executeBatch(weeklyBatch, 200);
    }
}