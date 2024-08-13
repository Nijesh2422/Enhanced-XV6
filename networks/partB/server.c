#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <sys/time.h>
typedef struct Numberofpackets
{
    int numberofpackets;
} Numberofpackets;
typedef struct Acknum
{
    int numbeofpackets;
} Acknum;
typedef struct Datapackets
{
    int index;
    char Data[15];
    time_t time;
} Datapackets;
typedef struct Acknowledgements
{
    int index;
} Acknowledgements;
int main()
{
    int sockfds = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (sockfds < 0)
    {
        printf("Socket Creation Failed\n");
        exit(1);
    }
    struct sockaddr_in ServerAddressPort, ClientAddressPort;
    ServerAddressPort.sin_port = htons(5100);
    ServerAddressPort.sin_family = AF_INET;
    ServerAddressPort.sin_addr.s_addr = htonl(INADDR_ANY);

    if (bind(sockfds, (struct sockaddr *)&ServerAddressPort, sizeof(ServerAddressPort)) < 0)
    {
        printf("Binding Failed\n");
        exit(1);
    }

    // while (1)
    // {
    Numberofpackets PackNos;
    Acknum A;
    A.numbeofpackets = -1;
    int ClientLength = sizeof(ClientAddressPort);
    while (A.numbeofpackets == -1)
    {
        if (recvfrom(sockfds, (char *)&PackNos, sizeof(PackNos), 0, (struct sockaddr *)&ClientAddressPort, &ClientLength) == -1)
        {
            printf("Recieving Number of packets Failed\n");
            exit(EXIT_FAILURE);
        }
        A.numbeofpackets = PackNos.numberofpackets;
        if (sendto(sockfds, (char *)&A, sizeof(A), 0, (struct sockaddr *)&ClientAddressPort, ClientLength) == -1)
        {
            printf("Sending Acknowledgement Failed\n");
            exit(EXIT_FAILURE);
        }
    }
    Datapackets *Data = (Datapackets *)malloc(sizeof(Datapackets) * A.numbeofpackets);
    for (int i = 0; i < A.numbeofpackets; i++)
    {
        Data[i].index = -1;
    }
    int k = A.numbeofpackets;
    Datapackets Datay;
    Acknowledgements Ay;
    // int nijesh = 0;
    while (k != 0)
    {
        bzero((char *)&Datay, sizeof(Datay));
        if (recvfrom(sockfds, (char *)&Datay, sizeof(Datay), 0, (struct sockaddr *)&ClientAddressPort, &ClientLength) == -1)
        {
            printf("Recieving Number of packets Failed\n");
            exit(EXIT_FAILURE);
        }
        Data[Datay.index].index = Datay.index;
        strcpy(Data[Datay.index].Data, Datay.Data);
        bzero((char *)&Ay, sizeof(Ay));
        Ay.index = Datay.index;
        // if (Ay.index % 5 != 0 || nijesh == A.numbeofpackets / 5)
        // {
        if (sendto(sockfds, (char *)&Ay, sizeof(Ay), 0, (struct sockaddr *)&ClientAddressPort, ClientLength) == -1)
        {
            printf("Sending Acknowledgement of %dth packet Failed\n", Ay.index);
            exit(EXIT_FAILURE);
        }
        else
        {
            k--;
        }
        // }
        // else
        // {
        //     nijesh++;
        // }
    }
    printf("Client: ");
    for (int i = 0; i < A.numbeofpackets; i++)
    {
        printf("%s", Data[i].Data);
    }
    free(Data);
    char buffer[1024]; // Adjust the buffer size as needed
    while (recvfrom(sockfds, buffer, sizeof(buffer), MSG_DONTWAIT, (struct sockaddr *)&ClientAddressPort, &ClientLength) > 0)
    {
        // Discard received data
    }
    printf("You: ");
    char Buffer2[4096];
    fgets(Buffer2, sizeof(Buffer2), stdin);
    int Buflen2 = strlen(Buffer2);
    int remainder2 = Buflen2 % 15;
    int numberofpackets2;
    if (remainder2 == 0)
    {
        numberofpackets2 = Buflen2 / 15;
    }
    else
    {
        numberofpackets2 = (Buflen2 / 15) + 1;
    }
    Numberofpackets PackNos2;
    Acknum A2;
    A2.numbeofpackets = -1;
    PackNos2.numberofpackets = numberofpackets2;
    int j = 0;
    while (j == 0)
    {
        if (sendto(sockfds, (char *)&PackNos2, sizeof(PackNos2), 0, (struct sockaddr *)&ClientAddressPort, ClientLength) == -1)
        {
            printf("Sending Number of Packets Failed\n");
            exit(EXIT_FAILURE);
        }
        if (recvfrom(sockfds, (char *)&A2, sizeof(A2), 0, (struct sockaddr *)&ClientAddressPort, &ClientLength) == -1)
        {
            printf("Recieving Acknowledgement for numberofpackets failed\n");
            exit(EXIT_FAILURE);
        }
        if (A2.numbeofpackets == PackNos2.numberofpackets)
        {
            j++;
        }
    }
    Datapackets *Data2 = (Datapackets *)malloc(sizeof(Datapackets) * numberofpackets2);
    int *SentorNot2 = (int *)malloc(sizeof(int) * numberofpackets2);
    for (int i = 0; i < numberofpackets2; i++)
    {
        Data2[i].index = i;
        strncpy(Data2[i].Data, Buffer2 + (i * 15), 15);
        SentorNot2[i] = 0;
    }
    int k2 = numberofpackets2;
    struct timeval time2;
    Acknowledgements Ab2;
    while (k2 != 0)
    {
        for (int i = 0; i < numberofpackets2; i++)
        {
            if (SentorNot2[i] == 0)
            {
                gettimeofday(&time2, NULL);
                Data2[i].time = time2.tv_sec;
                if (sendto(sockfds, (char *)&Data2[i], sizeof(Data2[i]), 0, (struct sockaddr *)&ClientAddressPort, ClientLength) == -1)
                {
                    printf("Sending %dth packet failed\n", i);
                }
            }
            bzero((char *)&Ab2, sizeof(Ab2));
            if (recvfrom(sockfds, (char *)&Ab2, sizeof(Ab2), MSG_DONTWAIT, (struct sockaddr *)&ClientAddressPort, &ClientLength) != -1)
            {
                gettimeofday(&time2, NULL);
                time_t hi2 = time2.tv_sec;
                if ((double)(hi2 - Data2[Ab2.index].time) <= 0.1)
                {
                    // printf("Recieved Acknowledgement of %dth Datapacket\n", Ab2.index);
                    k2--;
                    SentorNot2[Ab2.index] = 1;
                }
            }
        }
    }
    free(Data2);
    char bufer[1024]; // Adjust the buffer size as needed
    while (recvfrom(sockfds, bufer, sizeof(bufer), MSG_DONTWAIT, (struct sockaddr *)&ClientAddressPort, &ClientLength) > 0)
    {
        // Discard received data
    }
    // }
    if (close(sockfds) == -1)
    {
        printf("Closing Socket Failed\n");
        exit(1);
    }
}