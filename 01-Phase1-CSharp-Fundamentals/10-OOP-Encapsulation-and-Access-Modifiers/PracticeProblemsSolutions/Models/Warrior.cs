class Warrior : Character
{
    private string _higherDefense;
    
    public Warrior(string name) : base(name, "Warrior")
    {
        _higherDefense = "10"; // Warriors have higher defense
    }

    public void Shield()
    {
        int defense = int.Parse(_defense);
        defense += int.Parse(_higherDefense);
        _defense = defense.ToString();

        Console.WriteLine($"{Name} raises shield! Defense increased to {_defense}");
    }

    public new void LevelUp()
    {
        int level = int.Parse(_level);
        level++;
        _level = level.ToString();

        int maxHealth = int.Parse(_maxHealth);
        maxHealth += 20; // Increase max health on level up
        _maxHealth = maxHealth.ToString();

        int health = int.Parse(_health);
        health = maxHealth; // Restore health to new max
        _health = health.ToString();

        Console.WriteLine($"{Name} leveled up to level {_level}! Max Health is now {_maxHealth}");
    }
}