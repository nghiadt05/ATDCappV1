%{
    Doan Trung Nghia (C)
%}
function I_Refined = SP_Refinment(I,Sp2)
    %%
%     clc; close all; clear all;
%     load 'RawClassifierResult.mat';    
%     I = tmp_AllPIXLabels;
%     figure();imshow(I);  
    
    %%
    SizeVer = size(I,1);
    SizeHor = size(I,2);
    SW.InnerSize = [10,10]; % [HorSize,VerSize]
    SW.OuterSizeDif = [20,20]; % [HorSize,VerSize]
    SW.LoopHorDirCnt = floor(SizeHor/SW.InnerSize(1));
    SW.LoopVerDirCnt = floor(SizeVer/SW.InnerSize(2));
    SW.isVisual = false;
    SW.InnerPosThres = 0.25;
    SW.PosFilThre = 0.026;
    %%  
    for LoopVerIdx = 1 : SW.LoopVerDirCnt
        for LoopHorIdx = 1: SW.LoopHorDirCnt 
            %% Calculate TL and BR kinks of the inner window
            SW.InnerTL.Hor = 1 + SW.InnerSize(1)*(LoopHorIdx-1);
            SW.InnerTL.Ver = 1 + SW.InnerSize(2)*(LoopVerIdx-1);
            SW.InnerBR.Hor = min(SizeHor, SW.InnerTL.Hor + SW.InnerSize(1));
            SW.InnerBR.Ver = min(SizeVer, SW.InnerTL.Ver + SW.InnerSize(2));
            assert(SW.InnerTL.Hor <= SizeHor,'SW.InnerTL.Hor > SizeHor !');
            assert(SW.InnerTL.Ver <= SizeVer,'SW.InnerTL.Ver > SizeVer !');
            % visualization
            if(SW.isVisual)
                close all;
                I_Visual = I;
                I_Visual = insertShape(I_Visual,'Rectangle',...
                                       [SW.InnerTL.Hor, SW.InnerTL.Ver, SW.InnerBR.Hor-SW.InnerTL.Hor, SW.InnerBR.Ver-SW.InnerTL.Ver],...
                                       'LineWidth',2,'Color',[1 0 0 ]);
            end
            %fprintf('SW.InnerHorTL= %d SW.InnerVerTL= %d\n',SW.InnerTL.Hor,SW.InnerTL.Ver);
            %% Calculate all for kinks of the outer window
            SW.OuterTL.Hor = max(1, SW.InnerTL.Hor - SW.OuterSizeDif(1));
            SW.OuterTL.Ver = max(1, SW.InnerTL.Ver - SW.OuterSizeDif(2));
            SW.OuterBR.Hor = min(SizeHor, SW.OuterTL.Hor + SW.InnerSize(1) + 2*SW.OuterSizeDif(1));
            SW.OuterBR.Ver = min(SizeVer, SW.OuterTL.Ver + SW.InnerSize(2) + 2*SW.OuterSizeDif(2));
            assert(SW.OuterTL.Hor<=SizeHor);
            assert(SW.OuterBR.Hor<=SizeHor);
            assert(SW.OuterTL.Ver<=SizeVer);
            assert(SW.OuterBR.Ver<=SizeVer);
            % Visualization
            if SW.isVisual
                I_Visual = insertShape(I_Visual,'Rectangle',...
                                       [SW.OuterTL.Hor, SW.OuterTL.Ver, SW.OuterBR.Hor - SW.OuterTL.Hor, SW.OuterBR.Ver-SW.OuterTL.Ver],...
                                       'LineWidth',2,'Color',[0 1 0 ]);                             
                figure();imshow(I_Visual);
            end        
            %% Start refining inside a window
            SW.InnerWindow = I(SW.InnerTL.Ver:SW.InnerBR.Ver,SW.InnerTL.Hor:SW.InnerBR.Hor);
            SW.OuterWindow = I(SW.OuterTL.Ver:SW.OuterBR.Ver,SW.OuterTL.Hor:SW.OuterBR.Hor);
            if(SW.isVisual)
                figure();imshow(SW.InnerWindow);
                figure();imshow(SW.OuterWindow);
            end     
            % refine non-restricted area
            SW.NegInnerCnt = size(find(SW.InnerWindow==0),1);
            SW.PosInnerCnt = size(find(SW.InnerWindow>0),1);            
            SW.NegOuterCnt = size(find(SW.OuterWindow==0),1);
            if(SW.NegInnerCnt==0)
                SW.PosInnerRatio = 1;
            else
                SW.PosInnerRatio = SW.PosInnerCnt/SW.NegInnerCnt; 
            end
            SW.PosInnerOuterRatio = SW.PosInnerCnt/SW.NegOuterCnt;
            if( SW.PosInnerOuterRatio < SW.PosFilThre && ...
                SW.PosInnerOuterRatio > 0 && ...
                SW.PosInnerRatio > SW.InnerPosThres)               
%                I(SW.InnerTL.Ver:SW.InnerBR.Ver,SW.InnerTL.Hor:SW.InnerBR.Hor)=0;    
                 [tmpX, tmpY] = find(SW.InnerWindow>0);
                 for i=1:length(tmpX)
                    tmpNonZeroSPLabel = Sp2(SW.InnerTL.Ver + tmpX(i),SW.InnerTL.Hor + tmpY(i));
                    I((find(Sp2 == tmpNonZeroSPLabel))) = 0;
                 end                 
            end
            % refine restricted area
    %         SW.NegInnerCnt = size(find(SW.InnerWindow==0),1);
    %         SW.PosOuterCnt = size(find(SW.OuterWindow>0),1);
    %         SW.NegInnerRatio = SW.NegInnerCnt/SW.PosOuterCnt;
    %         if(SW.NegInnerRatio < SW.NegFilThre)
    %            meanPos = mean(SW.OuterWindow((find(SW.OuterWindow>0))));
    %            I(SW.InnerTL.Ver:SW.InnerBR.Ver,SW.InnerTL.Hor:SW.InnerBR.Hor)=meanPos;  
    %         end
            % visualization
%             if(SW.isVisual)
%                 figure();imshow(I);            
%             end
        end
    end
        I_Refined = I;
        figure();imshow(I);
end

