class Character
{
    protected string _health;
    protected string _maxHealth;
    protected string _attackPower;
    protected string _defense;
    protected string _xp;
    protected string _level;
    protected List<string> _inventory;
    public readonly string Name;
    public readonly string CharacterClass;

    public Character(string name, string characterClass)
    {
        Name = name;
        CharacterClass = characterClass;
        _health = "100";
        _maxHealth = "100";
        _attackPower = "10";
        _defense = "5";
        _xp = "0";
        _level = "1";
        _inventory = new List<string>();
    }

    public void Attack(Character target)
    {
        int attackPower = int.Parse(_attackPower);
        int targetDefense = int.Parse(target._defense);
        int damage = Math.Max(0, attackPower - targetDefense);

        int targetHealth = int.Parse(target._health);
        targetHealth -= damage;
        target._health = Math.Max(0, targetHealth).ToString();

        Console.WriteLine($"{Name} attacks {target.Name} for {damage} damage!");
    }

    public void TakeDamage(int damage)
    {
        int health = int.Parse(_health);
        health -= damage;
        _health = Math.Max(0, health).ToString();

        Console.WriteLine($"{Name} takes {damage} damage! Current Health: {_health}");
    }

    public void Heal(int amount)
    {
        int health = int.Parse(_health);
        int maxHealth = int.Parse(_maxHealth);
        health += amount;
        _health = Math.Min(maxHealth, health).ToString();

        Console.WriteLine($"{Name} heals for {amount}! Current Health: {_health}");
    }

    public void GainXP(int amount)
    {
        int xp = int.Parse(_xp);
        xp += amount;
        _xp = xp.ToString();

        Console.WriteLine($"{Name} gains {amount} XP! Current XP: {_xp}");
    }

    protected void LevelUp()
    {
        int level = int.Parse(_level);
        level++;
        _level = level.ToString();

        Console.WriteLine($"{Name} has leveled up! Current Level: {_level}");
    }

    public void DisplayStats()
    {
        Console.WriteLine($"Character: {Name} ({CharacterClass})");
        Console.WriteLine($"Health: {_health}/{_maxHealth}");
        Console.WriteLine($"Attack Power: {_attackPower}");
        Console.WriteLine($"Defense: {_defense}");
        Console.WriteLine($"XP: {_xp}");
        Console.WriteLine($"Level: {_level}");
        Console.WriteLine($"Inventory: {string.Join(", ", _inventory)}");
    }
}