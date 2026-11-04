import 'package:pdfx/pdfx.dart';
import 'package:pongo/exports.dart';

class PDFView extends StatefulWidget {
  const PDFView({super.key});

  @override
  State<PDFView> createState() => _PDFViewState();
}

class _PDFViewState extends State<PDFView> {
  final pdfPinchController = PdfControllerPinch(
    document:
        PdfDocument.openAsset('assets/pdf/Terms_and_conditions_Pongo.pdf'),
  );
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      key: const ValueKey(true),
      width: size.width,
      height: size.height,
      decoration: AppConstants().backgroundBoxDecoration,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              backButton(context),
              Expanded(
                child: Container(),
              ),
            ],
          ),
        ),
        body: PdfViewPinch(controller: pdfPinchController),
      ),
    );
  }
}
