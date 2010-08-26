% Read a configuration file like:
%    [Paths]
%    Data: /home/svoboda/viroomData/oscar/oscar_2c1p/   #config.paths.data
%    Camera-Filename: cam%d                             #config.paths.img[2]
%
%    [Files]
%    Image-Name-Prefix: oscar2c1p_                      #config.files.imnames
%    Basename: oscar                                    #config.files.basename
%    Num-Cameras: 2                                     #config.files.idxcams?
%    Num-Projectors: 2                                  #config.files.idxproj?
%    Projector-Data: files.txt
%    Image-Extension: jpg
%    
%    [Images]
%    LED_Size: 25
%    LED_Color: green
%    Subpix: 0.333333333
%    Camera_Resolution: 1392 1024
%    Projector_Resolution: 1024 768


function [config] = read_configuration(filename)

if nargin == 0
  % No argument given -- look for --config= on the command-line.
  found_cfg = 0;
  for cmdline_arg = argv()
    arg = cmdline_arg{1}
    if size(arg)(2) >= 10
      if strcmp(arg(1:9), '--config=')
        found_cfg = 1;
        filename = arg(10:size(arg,2));
      end
    end
  end
  if ~found_cfg
    error('missing --config=FILENAME command-line argument');
  end
end

% Do generic parsing based on metaconfiguration
config = read_generic_configuration(get_metaconfiguration(), filename);

% Do non-generic transformations.
% (These transformations are done to minimize our impact on outside code)
if ~isfield(config.paths, 'img') && isfield(config.paths, 'camera_filename')
  config.paths.img = [config.paths.data, config.paths.camera_filename];
end
if ~isfield(config.paths, 'projdata') && isfield(config.paths, 'projdatafile')
  config.files.projdata= [config.paths.data,config.paths.projdatafile]; % contains the projector data
end

% TODO: handle missing cameras
% TODO: config.files.cams2use
config.files.idxcams = [1:config.cal.num_cameras];
config.files.idxproj = [config.cal.num_cameras+1 : config.cal.num_cameras+config.cal.num_projectors];
% camera indexes handling
try, config.cal.cams2use; catch, config.cal.cams2use = config.files.idxcams; end

% Default initial settings for the estiamtion of the nonlinear distortion
% (1) ... camera view angle
% (2) ... estimate principal point?
% (3:4) ... parameters of the radial distortion
% (5:6) ... parameters of the tangential distortion
try, config.cal.nonlinpar; catch, config.cal.nonlinpar = [50,0,1,0,0,0]; end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% adding more and more non-linear paramaters might be tricky
% in case of bad data. You may fall in the trap of overfitting
% You may want to disable this
% update all possible parameters by default
try, config.cal.NL_UPDATE; catch, config.cal.NL_UPDATE = [1,1,1,1,1,1]; end



% configuration of the for the calibration process
try, config.cal.SQUARE_PIX;	      catch,  config.cal.SQUARE_PIX = 1;end	% most of the cameras have square pixels
try, config.cal.START_BA;		  catch,	config.cal.START_BA = 0; end
try, config.cal.DO_GLOBAL_ITER;	  catch,  config.cal.DO_GLOBAL_ITER = 1; end
try, config.cal.GLOBAL_ITER_THR;  catch,	config.cal.GLOBAL_ITER_THR = 1; end
try, config.cal.GLOBAL_ITER_MAX;  catch,	config.cal.GLOBAL_ITER_MAX = 10; end
try, config.cal.INL_TOL;		  catch,  config.cal.INL_TOL = 5; end;
try, config.cal.NUM_CAMS_FILL;	  catch,	config.cal.NUM_CAMS_FILL = 12; end;
try, config.cal.DO_BA;			  catch,	config.cal.DO_BA = 0; end;
try, config.cal.UNDO_RADIAL;	  catch,	config.cal.UNDO_RADIAL = 0; end;
try, config.cal.UNDO_HEIKK;		  catch,	config.cal.UNDO_HEIKK = 0; end; % only for testing, not a part of standard package
try, config.cal.NTUPLES;		  catch,  config.cal.NTUPLES	= 3; end;	% size of the camera tuples, 2-5 implemented
try, config.cal.MIN_PTS_VAL;	  catch,  config.cal.MIN_PTS_VAL = 30; end; % minimal number of correnspondences in the sample
try, config.cal.USE_NTH_FRAME;	      catch,  config.cal.USE_NTH_FRAME = 1;end	% most of the cameras have square pixels

% image extensions
try, config.files.imgext;  catch,  config.files.imgext	= 'jpg'; end;

% image resolution
try, config.imgs.res; catch, config.imgs.res		  = [640,480];	end;

% scale for the subpixel accuracy
% 1/3 is a good compromise between speed and accuracy
% for high-resolution images or bigger LEDs you may try, 1/1 or 1/2
try, config.imgs.subpix; catch, config.imgs.subpix = 1/3; end;

% data names
try, config.files.Pmats;     catch, config.files.Pmats	    = [config.paths.data,'Pmatrices.dat'];		end;
try, config.files.points;	 catch, config.files.points		= [config.paths.data,'points.dat'];		end;

fd = fopen(config.files.points);
if fd <0
  error(sprintf('could not open points data file "%s"',config.files.points))
else
  fclose(fd);
end


try, config.files.IdPoints;	 catch,	config.files.IdPoints	= [config.paths.data,'IdPoints.dat'];		end;
try, config.files.Res;		 catch,	config.files.Res		= [config.paths.data,'Res.dat'];		end;
try, config.files.IdMat;	 catch, config.files.IdMat		= [config.paths.data,'IdMat.dat'];			end;
try, config.files.inidx;	 catch, config.files.inidx		= [config.paths.data,'idxin.dat'];			end;
try, config.files.avIM;		 catch, config.files.avIM		= [config.paths.data,'camera%d.average.tiff'];		end;
try, config.files.stdIM;	 catch, config.files.stdIM		= [config.paths.data,'camera%d.std.tiff'];		end;
try, config.files.CalPar;	 catch, config.files.CalPar		= [config.paths.data,'camera%d.cal'];			end;
try, config.files.CalPmat;	 catch, config.files.CalPmat	= [config.paths.data,'camera%d.Pmat.cal'];			end;
try, config.files.StCalPar;	 catch,	config.files.StCalPar	= [config.paths.data,config.files.basename,'%d.cal'];	end;
try, config.files.rad;		 catch, config.files.rad		= [config.paths.data,config.files.basename,'%d.rad'];	end;
try, config.files.heikkrad;	 catch, config.files.heikkrad	= [config.paths.data,config.files.basename,'%d.heikk'];	end;
try, config.files.Pst;		 catch,	config.files.Pst		= [config.paths.data,'Pst.dat']; end;
try, config.files.Cst;		 catch,	config.files.Cst		= [config.paths.data,'Cst.dat']; end;
try, config.files.points4cal; catch,	config.files.points4cal = [config.paths.data,'cam%d.points4cal.dat']; end;
try, config.cal.BA_RADIAL;       catch, config.cal.BA_RADIAL = 0; end;


%  --- get_metaconfiguration ---
% 
% Returns an structure describing each named fields that must be producted by parsing the file.
function metacfg = get_metaconfiguration()

metacfg.Experiment.Name = ...
  { 'string', ...
    'Name of the experiment', ...
    { 'expname' }, ...
    { } ...
  };
metacfg.Paths.Data = ...
  { 'string', ...
    'Base directory for all data files', ...
    { 'paths', 'data' }, ...
    { 'slash_terminated', 'config_file_relative' } ...
  };
metacfg.Paths.Camera_Images = ...
  { 'string', ...
    'Template for camera directory (use %d for camera number)', ...
    { 'paths', 'img' }, ...
    { 'slash_terminated', 'data_relative' } ...
  };
metacfg.Files.Basename = ...
  { 'string', ...
    'basename', ...
    { 'files', 'basename' }, ...
    { } ...
  };
metacfg.Files.Image_Name_Prefix = ...
  { 'string', ...
    'Template for camera directory (use %d for camera number); wildcards allowed', ...
    { 'files', 'imnames' }, ...
    { } ...
  };
metacfg.Files.Image_Extension = ...
  { 'string', ...
    'Each for image filenames', ...
    { 'files', 'imgext' }, ...
    { } ...
  };
metacfg.Files.Projector_Data_Filename = ...
  { 'string', ...
    'File of projector data (within data dir)', ...
    { 'files', 'projdatafile' }, ...
    { } ...
  };
metacfg.Calibration.Num_Cameras = ...
  { 1, ...
    'number of cameras', ...
    { 'cal', 'num_cameras' }, ...
    { } ...
  };
metacfg.Calibration.Num_Projectors = ...
  { 1, ...
    'number of projectors', ...
    { 'cal', 'num_projectors' }, ...
    { } ...
  };
metacfg.Images.LED_Size = ...
  { '1', ...
    'average diameter of a LED in pixels', ...
    { 'imgs', 'LEDsize' }, ...
    { } ...
  };
metacfg.Images.LED_Color = ...
  { 'string', ...
    'color of the laser pointer', ...
    { 'imgs', 'LEDcolor' }, ...
    { } ...
  };
metacfg.Images.LED_Threshold = ...
  { 1, ...
    'threshold', ...
    { 'imgs', 'LEDthr' }, ...
    { } ...
  };
metacfg.Images.Subpix = ...
  { 1, ...
    'scale of the required subpixel accuracy', ...
    { 'imgs', 'subpix' }, ...
    { } ...
  };
metacfg.Images.Camera_Resolution = ...
  { 2, ...
    'camera image resolution', ...
    { 'imgs', 'res' }, ...
    { } ...
  };
metacfg.Images.Projector_Resolution = ...
  { 2, ...
    'projector resolution', ...
    { 'imgs', 'projres' }, ...
    { } ...
  };
metacfg.Calibration.Do_Global_Iterations = ...
  { 'boolean', ...
    'do global iterations', ...
    { 'cal', 'DO_GLOBAL_ITER' }, ...
    { } ...
  };
metacfg.Calibration.Global_Iteration_Max = ...
  { 1, ...
    'global iteration maximum', ...
    { 'cal', 'GLOBAL_ITER_MAX' }, ...
    { } ...
  };
metacfg.Calibration.Global_Iteration_Threshold = ...
  { 1, ...
    'global iteration threshold', ...
    { 'cal', 'GLOBAL_ITER_THR' }, ...
    { } ...
  };
metacfg.Calibration.Nonlinear_Parameters = ...
  { 6, ...
    'non-linear parameters (cite?)', ...
    { 'cal', 'nonlinpar' }, ...
    { } ...
  };
metacfg.Calibration.Nonlinear_Update = ...
  { 6, ...
    'non-linear update (cite?)', ...
    { 'cal', 'NL_UPDATE' }, ...
    { } ...
  };
metacfg.Calibration.Initial_Tolerance = ...
  { 1, ...
    'initial tolerance', ...
    { 'cal', 'INL_TOL' }, ...
    { } ...
  };
metacfg.Calibration.Num_Cameras_Fill = ...
  { 1, ...
    'num cameras fill', ...
    { 'cal', 'NUM_CAMS_FILL' }, ...
    { } ...
  };
metacfg.Calibration.Do_Bundle_Adjustment = ...
  { 1, ...
    'do Bundle Adjustment (slow)', ...
    { 'cal', 'DO_BA' }, ...
    { } ...
  };
metacfg.Calibration.Start_Bundle_Adjustment = ...
  { 1, ...
    'Start Bundle Adjustment (slow)', ...
    { 'cal', 'START_BA' }, ...
    { } ...
  };
metacfg.Calibration.Undo_Radial = ...
  { 'boolean', ...
    'undo radial distortion', ...
    { 'cal', 'UNDO_RADIAL' }, ...
    { } ...
  };
metacfg.Calibration.Undo_Heikk = ...
  { 'boolean', ...
    'undo radial distortion by using the parameters from the Jann Heikkila calibration toolbox?', ...
    { 'cal', 'UNDO_HEIKK' }, ...
    { } ...
  };
metacfg.Calibration.Min_Points_Value = ...
  { 1, ...
    'min points value', ...
    { 'cal', 'MIN_PTS_VAL' }, ...
    { } ...
  };
metacfg.Calibration.N_Tuples = ...
  { 1, ...
    'N Tuples', ...
    { 'cal', 'NTUPLES' }, ...
    { } ...
  };
metacfg.Calibration.Square_Pixels = ...
  { 1, ...
    'Square Pixels', ...
    { 'cal', 'SQUARE_PIX' }, ...
    { } ...
  };
