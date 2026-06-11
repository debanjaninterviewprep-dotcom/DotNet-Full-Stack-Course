class BugTask : TaskBase_Five
{
    public override string GetCategory() => "Bug";
    public override int GetPriorityScore() => 100;
}

class FeatureTask : TaskBase_Five
{
    public override string GetCategory() => "Feature";
    public override int GetPriorityScore() => 70;
}

class ChoreTask : TaskBase_Five
{
    public override string GetCategory() => "Chore";
    public override int GetPriorityScore() => 40;
}