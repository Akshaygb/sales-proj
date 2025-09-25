public class OverdueContractMonitor implements Schedulable {
    
    public void execute(SchedulableContext ctx) {
        OverdueContractBatch overdueBatch = new OverdueContractBatch();
        Database.executeBatch(overdueBatch, 200);
    }
}