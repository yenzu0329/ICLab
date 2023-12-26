######################################################
#                                                    #
#  Silicon Perspective, A Cadence Company            #
#  FirstEncounter IO Assignment                      #
#                                                    #
######################################################

Version: 2

#Example:  
#Pad: I_CLK 		W

#define your iopad location her
Pad: GNDC3        N
Pad: VDDP0        N
Pad: GNDP0        N
Pad: VDDC0        N
Pad: GNDC0        N
Pad: I_CLK        N
Pad: I_VALID      N
Pad: I_VALID2     N
Pad: VDDP1        N
Pad: GNDP1        N
Pad: VDDC1        N
Pad: GNDC1        N
  
Pad: VDDP2        W
Pad: GNDP2        W
Pad: VDDC2        W
Pad: GNDC2        W
Pad: I_MATRIX     W
Pad: I_MATRIX_S0  W
Pad: I_MATRIX_S1  W
Pad: VDDP3        W
Pad: GNDP3        W
Pad: VDDC3        W
 
Pad: PF1          S PFILL
Pad: GNDC4        S
Pad: VDDC4        S
Pad: GNDP4        S
Pad: VDDP4        S
Pad: O_VALID      S
Pad: O_VALUE      S
Pad: GNDC5        S
Pad: VDDC5        S
Pad: GNDP5        S
Pad: VDDP5        S
Pad: GNDC6        S

Pad: VDDC6        E
Pad: GNDP6        E
Pad: VDDP6        E
Pad: I_RESET      E
Pad: I_I_MAT_IDX  E
Pad: I_W_MAT_IDX  E
Pad: GNDC7        E
Pad: VDDC7        E
Pad: GNDP7        E
Pad: VDDP7        E

# corner pad
Pad: PCLR        SE PCORNER
Pad: PCUL        NW PCORNER
Pad: PCUR        NE PCORNER
Pad: PCLL        SW PCORNER