
.. raw:: latex

    \clearpage

.. raw:: html

    <script type="text/javascript">

        function getDocHeight(doc) {
            doc = doc || document;
            var body = doc.body, html = doc.documentElement;
            var height = Math.max( body.scrollHeight, body.offsetHeight,
                html.clientHeight, html.scrollHeight, html.offsetHeight );
            return height;
        }

        function setIframeHeight(id) {
            var ifrm = document.getElementById(id);
            var doc = ifrm.contentDocument? ifrm.contentDocument:
                ifrm.contentWindow.document;
            ifrm.style.visibility = 'hidden';
            ifrm.style.height = "10px"; // reset to minimal height ...
            // IE opt. for bing/msn needs a bit added or scrollbar appears
            ifrm.style.height = getDocHeight( doc ) + 4 + "px";
            ifrm.style.visibility = 'visible';
        }

    </script>

..
    ## 3n-skx-x710
    ### 64b-l2switching-base-scale-[avf,dpdk]
    10ge2p1x710-avf-eth-l2patch-ndrpdr
    10ge2p1x710-avf-eth-l2xcbase-ndrpdr
    10ge2p1x710-avf-eth-l2bdbasemaclrn-ndrpdr
    10ge2p1x710-dot1q-l2bdbasemaclrn-ndrpdr
    10ge2p1x710-eth-l2bdbasemaclrn-ndrpdr
    10ge2p1x710-eth-l2bdscale1mmaclrn-ndrpdr

3n-skx-x710
~~~~~~~~~~~

64b-l2switching-base-scale-avf
------------------------------

..
    .. raw:: html

        <center>
        <iframe id="01" onload="setIframeHeight(this.id)" width="700" frameborder="0" scrolling="no" src="../../_static/vpp/3n-skx-x710-64b-l2switching-base-scale-avf-ndr-tsa.html"></iframe>
        <p><br></p>
        </center>

    .. raw:: latex

        \begin{figure}[H]
            \centering
                \graphicspath{{../_build/_static/vpp/}}
                \includegraphics[clip, trim=0cm 0cm 5cm 0cm, width=0.70\textwidth]{3n-skx-x710-64b-l2switching-base-scale-avf-ndr-tsa}
                \label{fig:3n-skx-x710-64b-l2switching-base-scale-avf-ndr-tsa}
        \end{figure}

    .. raw:: latex

        \clearpage

.. raw:: html

    <center>
    <iframe id="02" onload="setIframeHeight(this.id)" width="700" frameborder="0" scrolling="no" src="../../_static/vpp/3n-skx-x710-64b-l2switching-base-scale-avf-pdr-tsa.html"></iframe>
    <p><br></p>
    </center>

.. raw:: latex

    \begin{figure}[H]
        \centering
            \graphicspath{{../_build/_static/vpp/}}
            \includegraphics[clip, trim=0cm 0cm 5cm 0cm, width=0.70\textwidth]{3n-skx-x710-64b-l2switching-base-scale-avf-pdr-tsa}
            \label{fig:3n-skx-x710-64b-l2switching-base-scale-avf-pdr-tsa}
    \end{figure}
