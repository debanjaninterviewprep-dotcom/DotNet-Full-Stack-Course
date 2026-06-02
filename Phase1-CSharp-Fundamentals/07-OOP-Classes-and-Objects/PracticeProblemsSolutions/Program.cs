using System;

namespace PracticeProblemsSolutions
{
	class Program
	{
		static void Main(string[] args)
		{
			Console.OutputEncoding = System.Text.Encoding.UTF8;

			// ===============================
			// Problem 1: Bank Account Class
			// ===============================
			// Create BankAccount with properties, deposit/withdraw methods, auto-properties, validation for insufficient balance.
			Console.WriteLine("Problem 1: Bank Account Class");

			Random random = new Random();
			BankAccount? account = null;   // ✅ Declare outside

			bool problem1Running = true;
			while (problem1Running)   // ✅ Loop menu
			{
				Console.WriteLine("\n1. Create a new bank account");
				Console.WriteLine("2. Deposit money");
				Console.WriteLine("3. Withdraw money");
				Console.WriteLine("4. Display balance");
				Console.WriteLine("5. Next problem");

				Console.Write("Choose an option: ");
				int choice = int.Parse(Console.ReadLine() ?? "0");

				switch (choice)
				{
					case 1:
						Console.Write("Enter account holder name: ");
						string accountHolder = Console.ReadLine() ?? string.Empty;

						string randomPart = random.Next(100000, 999999).ToString();
						string accountNumber = $"ACC{randomPart}";

						account = new BankAccount(accountNumber, accountHolder);

						Console.WriteLine($"✅ Account created!");
						Console.WriteLine($"Account Number: {account.accountNumber}");
						Console.WriteLine($"Holder: {account.AccountHolder}");
						break;

					case 2:
						if (account == null)
						{
							Console.WriteLine("❌ Create account first!");
							break;
						}

						Console.Write("Enter amount to deposit: ");
						decimal depositAmount = decimal.Parse(Console.ReadLine() ?? "0");
						account.Deposit(depositAmount);
						break;

					case 3:
						if (account == null)
						{
							Console.WriteLine("❌ Create account first!");
							break;
						}

						Console.Write("Enter amount to withdraw: ");
						decimal withdrawAmount = decimal.Parse(Console.ReadLine() ?? "0");
						account.Withdraw(withdrawAmount);
						break;

					case 4:
						if (account == null)
						{
							Console.WriteLine("❌ Create account first!");
							break;
						}

						account.DisplayBalance();
						break;

					case 5:
						Console.WriteLine("Moving to Problem 2...");
						problem1Running = false;
						break;

					default:
						Console.WriteLine("Invalid option.");
						break;
				}
			}

			// ===============================
			// Problem 2: Student Grade Book
			// ===============================
			// Student class with static auto-increment ID, array of scores, GetAverage, GetGrade, GetHighest/Lowest, formatted display.

			Console.WriteLine("\nProblem 2: Student Grade Book");

			Student? student = null;   // ✅ Declare outside

			bool problem2Running = true;
			while (problem2Running)   // ✅ Loop menu
			{
				Console.WriteLine("1. Create a new student");
				Console.WriteLine("2. Add a score");
				Console.WriteLine("3. Display student info");
				Console.WriteLine("4. Get average score and grade");
				Console.WriteLine("5. Get highest and lowest scores");
				Console.WriteLine("6. Exit");

				Console.Write("Choose an option: ");
				int studentChoice = int.Parse(Console.ReadLine() ?? "0");

				switch (studentChoice)
				{
					case 1:
						Console.Write("Enter student name: ");
						string studentName = Console.ReadLine() ?? string.Empty;
						student = new Student(studentName);
						Console.WriteLine($"✅ Student created! ID: {student.Id}, Name: {student.Name}");
						break;
					case 2:
						if (student == null)
						{
							Console.WriteLine("❌ Create student first!");
							break;
						}

						Console.Write("Enter score to add: ");
						int score = int.Parse(Console.ReadLine() ?? "0");
						student.AddScore(score);
						Console.WriteLine("✅ Score added!");
						break;
					case 3:
						if (student == null)
						{
							Console.WriteLine("❌ Create student first!");
							break;
						}
						student.DisplayInfo();
						break;
					case 4:
						if (student == null)
						{
							Console.WriteLine("❌ Create student first!");
							break;
						}
						Console.WriteLine($"Average Score: {student.GetAverageScore():F2}");
						Console.WriteLine($"Grade: {student.GetGrade()}");
						break;
					case 5:
						if (student == null)
						{
							Console.WriteLine("❌ Create student first!");
							break;
						}

						var (highest, lowest) = student.GetHighestAndLowest();
						Console.WriteLine($"Highest Score: {highest}");
						Console.WriteLine($"Lowest Score: {lowest}");
						break;
					case 6:
						Console.WriteLine("Exiting...");
						problem2Running = false;
						break;
					default:
						Console.WriteLine("Invalid option.");
						break;
				}
			}


			// ===============================
			// Problem 3: Rectangle & Circle with Static Utility
			// ===============================
			// Shape classes with Area/Perimeter, static ShapeHelper for comparisons and square checking.

			Console.WriteLine("\nProblem 3: Rectangle & Circle with Static Utility");

			Rectangle rectangle = new Rectangle(4, 5);
			rectangle.DisplayInfo();
			Circle circle = new Circle(3);
			circle.DisplayInfo();
			double largerArea = ShapeHelper.CompareAreas(rectangle.GetArea(), circle.GetArea());
			Console.WriteLine($"The larger area is: {largerArea}");


			// ===============================
			// Problem 4: Constructor Overloading - Employee System
			// ===============================
			// Employee class with 4 overloaded constructors using this() chaining, promote/deactivate methods.

			Console.WriteLine("\nProblem 4: Constructor Overloading - Employee System");

			Employee emp1 = new Employee("Alice");
			Employee emp2 = new Employee("Bob", "HR");
			Employee emp3 = new Employee("Charlie", "IT", 60000);
			Employee emp4 = new Employee("Diana", "Finance", 70000, DateTime.Now);
			emp1.DisplayInfo();
			emp2.DisplayInfo();
			emp3.DisplayInfo();
			emp4.DisplayInfo();
			emp1.Promote(5000);
			emp2.Deactivate();

			Employee.DisplayAllEmployees(new List<Employee> { emp1, emp2, emp3, emp4 });


			// ===============================
			// Problem 5: TaskFlow Project Manager
			// ===============================
			// User, TaskItem, and Project classes demonstrating constructors, auto-properties, computed properties, static counters.

			Console.WriteLine("\nProblem 5: TaskFlow Project Manager");
			User user1 = new User("Alice", "alice@taskflow.dev", "Designer");
			User user2 = new User("Bob", "bob@taskflow.dev", "Developer");

			Project project = new Project("TaskFlow Redesign");

			TaskItem t1 = new TaskItem("Design new UI", "Refresh the board layout", "High");
			TaskItem t2 = new TaskItem("Implement backend", "Wire up the API", "Medium");
			t1.AssignToUser(user1);
			t2.AssignToUser(user2);

			project.AddTask(t1);
			project.AddTask(t2);

			project.DisplayInfo();
			project.GetCompletionPercentage();

			project.Tasks[0].MarkAsCompleted();
			project.GetCompletionPercentage();
		}
	}
}

