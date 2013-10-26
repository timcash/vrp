import 'dart:html';
import 'dart:math';

Element notes = query("#fps");
CanvasElement canvas;
num fpsAverage;
var width;
var height;
List Stops = new List();
num STOPCOUNT = 30;
num GENSIZE = 1000;
num NUMGEN = 1000;
num MUTATIONRATE = 0.1;
Random rng = new Random();
Map distanceMatrix = new Map();
List<PathDna> population = new List<PathDna>();
int currentGen = 0;
List<PathDna> bestn = new List<PathDna>();
int SCREENSIZE = 0;
int ELITESIZE = 250;

void main() {
  
  // Measure the canvas element.
  canvas = query("#area");
  Rectangle rect = canvas.parent.client;
  width = rect.width;
  height = rect.height;
  canvas.width = width;
  canvas.height = height;

  //printPopulation();
  
  //print(calcDistance(0, 0, 3, 4));
  
//  querySelector("#sample_text_id")
//    ..text = "Click me!"
//    ..onClick.listen(reverseText);
  
  Start();
}

void Start()
{
  
  for(num i = 0; i < STOPCOUNT; i++)
  {
    int x = rng.nextInt(width);
    int y = rng.nextInt(height);
    Point p = new Point(x,y);
//    Point p = new Point.polar((i/STOPCOUNT)*(2*PI), canvas.width/3);
//    p.x += canvas.width/2;
//    p.y += canvas.height/2;
    Stops.add(p);
  }
  
  distanceMatrix = createDistanceMatrix(Stops);
  population = createFirstGen();
  updateFitness(population);
  bestn = findBestN(population,ELITESIZE);
  DrawPath(bestn[0].stopOrder);
  print(bestn[0].totalDistance);
  requestRedraw();
}

void requestRedraw() {
  window.requestAnimationFrame(draw);
}

void draw(num _) {
  List parents = selectParents(population);
  List newPop = makeNewGen(parents);
  population = newPop;
  updateFitness(population);
  bestn = findBestN(population,ELITESIZE);
  if(currentGen % 10 == 0)
  {
    DrawPath(bestn[0].stopOrder);
  }
  print(bestn[0].totalDistance);
  currentGen += 1;
  print(currentGen);
  requestRedraw();
}

List createFirstGen()
{
  List pop = new List();
  for(int i =0; i < GENSIZE; i++)
  {
    PathDna pd = new PathDna(STOPCOUNT);
    pop.add(pd);
//    print("--------------------");
//    print(pd.totalDistance);
//    print(pd.toString());
  }
  
  return pop;
}

void printPopulation()
{
  print("==================================");
  print("==================================");
  for(PathDna p in population)
  {
    print("-------------");
    print(p.toString());
    print(p.totalDistance);
    print(p.fitness);
  }
}

List findBestN(List dnas,int n)
{
  dnas.sort((a,b)=> a.totalDistance.compareTo(b.totalDistance));
  
  return dnas.getRange(0, n).toList();
}

List selectParents(List pop)
{
  List parents = new List();
  while(parents.length < GENSIZE)
  {
    for(PathDna p in pop)
    {
      num roll = rng.nextDouble();
      if(roll < p.fitness)
      {
        parents.add(p);
      }
    }
  }
  return parents;
}

List makeNewGen(List pop)
{
  List newpop = new List();
  int i = 0;
  
  newpop.add(bestn[0]);
  newpop.add(bestn[1]);
  
  while(newpop.length < GENSIZE)
  {
    PathDna child1 = new PathDna.Pmx(pop[i], pop[i+1]);
    PathDna child2 = new PathDna.Pmx(pop[i+1], pop[i]);
    i+=2;
    newpop.add(child1);
    newpop.add(child2);
    
    if(i > pop.length-2)
    {
      i = 0;
    }
  }
  return newpop;
}

List updateFitness(List dnas)
{
  List distances = new List();
  for(PathDna p in dnas)
  {
    distances.add(p.totalDistance);
  }
  distances.sort();
  num bestDistance = distances[0];
  for(PathDna p in dnas)
  {
    
    p.fitness = 1.0/(p.totalDistance/bestDistance);
    //print(p.fitness);
  }
}

class PathDna
{
  
  List stopOrder = new List();
  num fitness = 0;
  num totalDistance = 0;
  int crossPoint = 0;
  
  PathDna(num length){
    this.stopOrder = createRandomStopList(length);
    this.fitness = 0;
    this.calcDistance();
  }
  
  PathDna.Pmx(PathDna a, PathDna b)
  {
    int length = a.stopOrder.length;
    int pick = rng.nextInt(length-1);
    this.crossPoint = pick;
    List aOrder = new List.from(a.stopOrder);
    List bOrder = new List.from(b.stopOrder);
    for(int i =0; i < pick; i++)
    {
//      print("------------------------");
//      print(aOrder);
//      print(bOrder);
//      print("------------------------");
      int incoming = bOrder[i];
      int outgoing = aOrder[i];
      int idxOfReplaced = aOrder.indexOf(incoming, 0);
      
      aOrder[idxOfReplaced] = outgoing;
      aOrder[i] = incoming;
    }
    this.stopOrder = aOrder;
    this.mutate2(MUTATIONRATE);
    
    
    this.fitness = 0;
    this.calcDistance();
  }
  
  void calcDistance(){
    this.totalDistance = 0;
    for(num i =0; i < this.stopOrder.length-1; i++)
    {
      int idx1 = this.stopOrder[i];
      int idx2 = this.stopOrder[i+1];
      this.totalDistance += distanceMatrix['$idx1''_''$idx2'];
    }
  }
  
  void mutate(num rate)
  {
    int length = this.stopOrder.length;
    for(num i = 0; i < length; i++){
      num roll = rng.nextDouble();
      if(roll <= rate){
        //swap this location, pick the other location to swap with

        int pick = rng.nextInt(length-1);
        //print("mutation occurs at $i and $pick");
        //print(this.stopOrder);
        
        int temp1 = this.stopOrder[i];
        int temp2 = this.stopOrder[pick];
        this.stopOrder[i] = temp2;
        this.stopOrder[pick] = temp1;
        //print(this.stopOrder);
      }
    }
  }
  
  void mutate2(num rate)
  {
    int length = this.stopOrder.length;
    num roll = rng.nextDouble();
    if(roll <= rate){
      int pick = rng.nextInt(length-1);
      int val = this.stopOrder[pick];
      int put = rng.nextInt(length-2);
      this.stopOrder.removeAt(pick);
      this.stopOrder.insert(put, val);
    }

  }
  
  String toString(){
    return this.stopOrder.toString();
  }
  
}

Map createDistanceMatrix(List points)
{
  Map m = new Map();
  for(int i=0;i<points.length;i++)
  {
    for(int j=0;j<points.length;j++)
    {
      Point p1 = points[i];
      Point p2 = points[j];
      m['$i''_''$j'] = calcDistance(p1.x, p1.y, p2.x, p2.y);
    }
  }
  return m;
}

num calcDistance(num x1, num y1,num x2,num y2)
{
  num xdist = pow(x2-x1,2);
  num ydist = pow(y2-y1,2);
  num dist = sqrt(xdist + ydist);
  return dist;
}

class Point {
  num x, y;
  Point(this.x, this.y);
  Point.zero() : x = 0, y = 0;
  Point.polar(num theta, num radius) {
    x = cos(theta) * radius;
    y = sin(theta) * radius;
  }
}

List createRandomStopList(num length){
  List tempList = new List();
  for(num i =0; i<length;i++){
    tempList.add(i);
  }
  tempList.shuffle(rng);
  return tempList;
}

void DrawPath(List stopIndexs)
{  
  var context = canvas.context2D;
  context.clearRect(0, 0, width, height);
  context.beginPath();
  Point p1 = Stops[stopIndexs[0]];
  context.moveTo(p1.x, p1.y);
  
  for(num i in stopIndexs)
  {
    Point p = Stops[i];
    context.lineTo(p.x,p.y);
  }
  context.stroke();
}