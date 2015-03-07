function out = ImageProcessingToolboxAvailable()
    toolboxName1 = 'Image Processing Toolbox';
    toolboxName2 = 'Image_Toolbox';
    v = ver;
    installed = any(strcmp(toolboxName1, {v.Name}));
    % where toolboxName is the name of the toolbox you want to check.
    % To check that the licence is valid, use
    licenseValid = license('test', toolboxName2);
    out = installed && licenseValid;
    if ~out
        disp('Image Processing Toolbox not found')
    end
end