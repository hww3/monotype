
  constant is_real_js = 1;
  int is_combined_space = 0;
  
  // after the line has been rendered, this is the width to be added to the minimum width of a justifying space.
  float calculated_width;
  object matrix;

  static void create(object _matrix)
  {
    matrix = _matrix;	
  }