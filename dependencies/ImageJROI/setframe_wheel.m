function setframe_wheel(~, eventdata, obj, varargin)
type = get(gco, 'type');
uicontr_flag = strcmp(type, 'uicontrol');
if uicontr_flag
    steps = get(gco, 'SliderStep');
    step =  round( steps(2)*obj.T );
else
    step = 1;
end
%             if (strcmp(type, 'image') || uicontr_flag)
obj.tt = round(get(obj.slider, 'Value'));
if eventdata.VerticalScrollCount > 0
    obj.tt = max(1, obj.tt - step);
else
    obj.tt = min(obj.T, obj.tt + step);
end
set(obj.slider, 'Value', obj.tt)
setframe_slide(obj.slider, [], obj, varargin)
%             end
end