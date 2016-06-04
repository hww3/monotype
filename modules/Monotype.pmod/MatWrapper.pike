          constant _is_matwrapper = 1;
                int|float adjust_space;

                object mat;
                
                protected void create(object _mat, int|float _adjust_space)
                {
                  if(_mat == 1) throw(Error.Generic("whoa!\n"));
                        mat = _mat;
                        adjust_space = _adjust_space;
                }
                
                protected mixed `[](mixed a)
                {
                        mixed m = ::`[](a);
                        if(m) return m;
                        else return mat[a];
                }
                
                float get_set_width()
                {
                        return (float)(adjust_space + mat->get_set_width());
                }
                
                
                protected mixed `->(mixed a)
                {
                        mixed m = ::`->(a);
                        if(m) return m; 
                        else return mat[a];
                }
                mixed _sprintf(mixed x)
                {
                  return "MatWrapper(" + sprintf("%O", mat) + ")";
                }

