class Mage : Character
{
    private string _higherAttack;

    public Mage(string name) : base(name, "Mage")
    {
        _higherAttack = "10"; // Mages have higher attack
    }

    public void CastSpell()
    {
        int attackPower = int.Parse(_attackPower);
        attackPower += int.Parse(_higherAttack);
        _attackPower = attackPower.ToString();

        Console.WriteLine($"{Name} casts a powerful spell! Attack increased to {_attackPower}");
    }

    public new void LevelUp()
    {
        int level = int.Parse(_level);
        level++;
        _level = level.ToString();

        int maxHealth = int.Parse(_maxHealth);
        maxHealth += 10; // Increase max health on level up
        _maxHealth = maxHealth.ToString();

        int health = int.Parse(_health);
        health = maxHealth; // Restore health to new max
        _health = health.ToString();

        Console.WriteLine($"{Name} leveled up to level {_level}! Max Health is now {_maxHealth}");
    }
}