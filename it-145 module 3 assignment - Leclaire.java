//Anthony Leclaire


public class Dog {

    // Private attributes from the UML diagram
    private int dogSpaceNumber;   // Space number assigned to the dog
    private double dogWeight;     // Weight of the dog in pounds
    private boolean grooming;     // Whether the dog needs grooming (true or false)

    // No-argument constructor
    // Initializes all attributes to default values
    public Dog() {
        this.dogSpaceNumber = 0;
        this.dogWeight = 0.0;
        this.grooming = false;
    }

    // Parameterized constructor
    // Initializes all attributes with the values passed in
    public Dog(int dogSpaceNumber, double dogWeight, boolean grooming) {
        this.dogSpaceNumber = dogSpaceNumber;
        this.dogWeight = dogWeight;
        this.grooming = grooming;
    }

    // Getter method for dogSpaceNumber
    public int getDogSpaceNumber() {
        return dogSpaceNumber;
    }

    // Setter method for dogSpaceNumber
    public void setDogSpaceNumber(int dogSpaceNumber) {
        this.dogSpaceNumber = dogSpaceNumber;
    }

    // Getter method for dogWeight
    public double getDogWeight() {
        return dogWeight;
    }

    // Setter method for dogWeight
    public void setDogWeight(double dogWeight) {
        this.dogWeight = dogWeight;
    }

    // Getter method for grooming
    public boolean getGrooming() {
        return grooming;
    }

    // Setter method for grooming
    public void setGrooming(boolean grooming) {
        this.grooming = grooming;
    }
}