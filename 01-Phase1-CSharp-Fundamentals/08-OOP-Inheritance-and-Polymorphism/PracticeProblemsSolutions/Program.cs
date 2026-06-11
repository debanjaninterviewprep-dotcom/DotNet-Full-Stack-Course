using System;

namespace PracticeProblemsSolutions
{
	class Program
	{
		static void Main(string[] args)
		{
			// ===============================
			// Problem 1: Vehicle Hierarchy
			// ===============================
			// Base Vehicle class with virtual Display, Car/Motorcycle/Truck subclasses override to include type-specific properties.

			Car myCar = new Car("Toyota", "Camry", 2020, 120, 4);
			Motorcycle myMotorcycle = new Motorcycle("Harley-Davidson", "Street 750", 2019, 100, false);
			Car myTruck = new Car("Volvo", "FH16", 2021, 40, 2);
			myCar.DisplayInfo();
			myMotorcycle.DisplayInfo();
			myTruck.DisplayInfo();


			// ===============================
			// Problem 2: Shape Calculator with Polymorphism
			// ===============================
			// Shape base class with virtual Area/Perimeter, Rectangle/Circle/Triangle implementations, polymorphic array processing.

			Rectangle rect = new Rectangle(5, 10);
			Circle circle = new Circle(7);
			Triangle triangle = new Triangle(6, 8, 5, 6, 7);

			double totalArea = rect.Area() + circle.Area() + triangle.Area();
			double totalPerimeter = rect.Perimeter() + circle.Perimeter() + triangle.Perimeter();

			Console.WriteLine("Shape Details:");
			rect.DisplayInfo();
			circle.DisplayInfo();
			triangle.DisplayInfo();
			Console.WriteLine($"Total Area: {totalArea}, Total Perimeter: {totalPerimeter}");


			// ===============================
			// Problem 3: Employee Payroll System
			// ===============================
			// Base Employee with virtual CalculatePay, subclasses: Salaried, Hourly (with overtime), Commission with their own calculations.

			Employee[] employees = new Employee[]
			{
				new SalariedEmployee(1, "Alice", "HR", 5000) { bonus = 500 },
				new HourlyEmployee(2, "Bob", "IT", 20, 45),
				new CommissionEmployee(3, "Charlie", "Sales", 3000, 0.1, 20000),
				new SalariedEmployee(4, "Diana", "Finance", 6000) { bonus = 1000 },
				new HourlyEmployee(5, "Eve", "Support", 15, 38),
				new CommissionEmployee(6, "Frank", "Marketing", 2500, 0.15, 15000),
				new SalariedEmployee(7, "Grace", "Operations", 5500) { bonus = 750 },
				new HourlyEmployee(8, "Heidi", "Logistics", 18, 42)
			};

			Console.WriteLine("|| Payroll Report ||");
			foreach (var emp in employees)
			{
				Console.WriteLine($"ID: {emp.id}, Name: {emp.name}, Department: {emp.department}, Role: {emp.GetRole()}, Pay: {emp.CalculatePay():C}");
			}

			Console.WriteLine($"Total Payroll Cost: {employees.Sum(e => e.CalculatePay()).ToString("C")}");
			Console.WriteLine($"Average Pay: {(employees.Sum(e => e.CalculatePay()) / employees.Length).ToString("C")}");
			Console.WriteLine($"Highest Pay: {employees.Max(e => e.CalculatePay()).ToString("C")}");
			Console.WriteLine($"Lowest Pay: {employees.Min(e => e.CalculatePay()).ToString("C")}");



			// ===============================
			// Problem 4: Type Checking & Casting Challenge
			// ===============================
			// Use is/as keywords and pattern matching to classify vehicles, extract type-specific info, count by type.

			var vehicles = Service.SeedVehicles();

			Console.WriteLine("=== TYPE CHECKING DEMO ===\n");

			Service.CountVehicleTypes(vehicles);
			Service.PrintCarDetailsUsingIs(vehicles);
			Service.PrintCarModelUsingAs(vehicles);
			Service.ClassifyVehiclesUsingSwitch(vehicles);
			Service.FilterCarsWithMoreThanTwoDoors(vehicles);


			// ===============================
			// Problem 5: TaskFlow Task Type System
			// ===============================
			// TaskBase with BugTask/FeatureTask/ChoreTask subclasses, polymorphic display, sprint capacity calculation.

			// TODO: Write your solution here

		}
	}
}
